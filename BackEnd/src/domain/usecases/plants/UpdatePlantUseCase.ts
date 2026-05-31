/**
 * @file UpdatePlantUseCase.ts
 * @description Caso de uso para actualizar una planta existente.
 * Recalcula nextWatering/nextPruning si cambian las frecuencias.
 * @module Plants
 * @layer Domain
 *
 * @implements {IUpdatePlantUseCase}
 * @injectable
 * @dependencies IPlantRepository, IPlantMapper
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IUpdatePlantUseCase } from '../../interfaces/usecases/plants/IUpdatePlantUseCase.js';
import type { IPlantRepository } from '../../repositories/IPlantRepository.js';
import type { IPlantSpeciesRepository } from '../../repositories/IPlantSpeciesRepository.js';
import type { IPlantMapper } from '../../../data/IMappers/IPlantMapper.js';
import type { UpdatePlantRequestDTO } from '../../dtos/plants/update-plant-request.dto.js';
import type { PlantResponseDTO } from '../../dtos/plants/plant-response.dto.js';
import type { Plant } from '../../entities/Plant.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';
import { verifyOwnership } from '../../../presentation/validators/ownershipValidator.js';

/**
 * Calcula el factor estacional de riego para un mes dado.
 * dic–feb = invierno, jun–ago = verano. Primavera y otoño = 1.0 (sin ajuste).
 * @private
 */
function getSeasonalFactor(month: number, adj?: { summer?: number; winter?: number }): number {
  if (!adj) return 1.0;
  if (month >= 6 && month <= 8)  return adj.summer ?? 1.0; // verano
  if (month >= 12 || month <= 2) return adj.winter ?? 1.0; // invierno
  return 1.0;
}

/**
 * Actualiza los campos de una planta verificando ownership.
 * Si cambia la frecuencia de riego o poda, recalcula las próximas fechas.
 *
 * @implements {IUpdatePlantUseCase}
 * @injectable
 * @dependencies IPlantRepository, IPlantSpeciesRepository, IPlantMapper
 */
@injectable()
export class UpdatePlantUseCase implements IUpdatePlantUseCase {
  constructor(
    @inject(TYPES.IPlantRepository)        private readonly plantRepo: IPlantRepository,
    @inject(TYPES.IPlantSpeciesRepository) private readonly speciesRepo: IPlantSpeciesRepository,
    @inject(TYPES.IPlantMapper)            private readonly mapper: IPlantMapper,
  ) {}

  /**
   * @param plantId — Id de la planta a actualizar.
   * @param dto — Campos a actualizar (PATCH semantics).
   * @param userId — Id del usuario autenticado.
   * @returns PlantResponseDTO actualizado.
   * @throws {NotFoundException} Si la planta no existe.
   * @throws {UnauthorizedException} Si el usuario no es propietario.
   */
  async execute(plantId: string, dto: UpdatePlantRequestDTO, userId: string): Promise<PlantResponseDTO> {
    // Descompuesto en helpers privados para mantener `execute` < 20 líneas
    // y una responsabilidad clara por método.
    const plant = await this._loadAndAuthorize(plantId, userId);
    const updateData = await this._buildUpdateData(plant, dto);
    // Cast como en ProcessPendingRemindersUseCase: `pendingRainAdjustment: null`
    // no encaja en la firma `PendingRainAdjustment | undefined`, pero el
    // repositorio acepta el null y MongoDB lo persiste tal cual ($set null).
    const updated = await this.plantRepo.update(plantId, updateData as unknown as Partial<Plant>);
    return this.mapper.toResponseDTO(updated);
  }

  /**
   * Carga la planta y verifica ownership. Lanza NotFoundException si no
   * existe o está soft-deleted; UnauthorizedException si el user no es
   * propietario.
   * @private
   */
  private async _loadAndAuthorize(plantId: string, userId: string): Promise<Plant> {
    const plant = await this.plantRepo.findById(plantId);
    if (!plant || plant.deletedAt) throw new NotFoundException('Plant', plantId);
    verifyOwnership(plant.userId, userId, 'Plant');
    return plant;
  }

  /**
   * Construye el objeto de actualización aplicando PATCH semantics + los
   * recálculos de fechas que dependen de los cambios del DTO.
   * @private
   */
  private async _buildUpdateData(
    plant: Plant,
    dto: UpdatePlantRequestDTO,
  ): Promise<Record<string, unknown>> {
    const nextWatering = await this._computeNextWatering(plant, dto);
    const nextPruning  = this._computeNextPruning(plant, dto);

    const updateData: Record<string, unknown> = {
      ...(dto.name                      !== undefined && { name: dto.name }),
      ...(dto.speciesId                 !== undefined && { speciesId: dto.speciesId }),
      ...(dto.photo                     !== undefined && { photo: dto.photo }),
      ...(dto.location                  !== undefined && { location: dto.location }),
      ...(dto.wateringFrequency         !== undefined && { wateringFrequency: dto.wateringFrequency, nextWatering }),
      ...(dto.lightNeed                 !== undefined && { lightNeed: dto.lightNeed }),
      ...(dto.pruningFrequency          !== undefined && { pruningFrequency: dto.pruningFrequency, nextPruning }),
      ...(dto.notes                     !== undefined && { notes: dto.notes }),
      ...(dto.considerWeatherForWatering !== undefined && { considerWeatherForWatering: dto.considerWeatherForWatering }),
      ...(dto.lastWatered               !== undefined && { lastWatered: new Date(dto.lastWatered) }),
    };

    // Cuando el usuario registra un riego manual (lastWatered presente en
    // el DTO), limpiamos `pendingRainAdjustment`. Sin esto, el cron del
    // día siguiente (_processYesterdayRain) podría ejecutar el rollback
    // de la previsión de lluvia y sobreescribir el nextWatering recién
    // fijado por el usuario, devolviendo a la planta a la fecha
    // pre-previsión y descartando el riego registrado.
    if (dto.lastWatered !== undefined && plant.pendingRainAdjustment) {
      updateData['pendingRainAdjustment'] = null;
    }
    return updateData;
  }

  /**
   * Recalcula `nextWatering` solo si el DTO cambia la frecuencia, aplicando
   * el `seasonalFactor` de la especie. Si no se toca la frecuencia,
   * devuelve el valor actual de la planta sin cambios.
   * @private
   */
  private async _computeNextWatering(
    plant: Plant,
    dto: UpdatePlantRequestDTO,
  ): Promise<Date | undefined> {
    if (dto.wateringFrequency === undefined) return plant.nextWatering;

    const newFreq = dto.wateringFrequency;
    let effectiveFreq = newFreq;
    if (plant.speciesId) {
      const species = await this.speciesRepo.findById(plant.speciesId).catch(() => null);
      const factor  = getSeasonalFactor(new Date().getMonth() + 1, species?.seasonalWateringAdjustment);
      effectiveFreq = Math.max(1, Math.round(newFreq * factor));
    }
    const d = new Date();
    d.setDate(d.getDate() + effectiveFreq);
    return d;
  }

  /**
   * Recalcula `nextPruning` si el DTO cambia la frecuencia de poda.
   * Si la frecuencia se establece a falsy (0/null), devuelve undefined.
   * @private
   */
  private _computeNextPruning(plant: Plant, dto: UpdatePlantRequestDTO): Date | undefined {
    if (dto.pruningFrequency === undefined) return plant.nextPruning;
    if (!dto.pruningFrequency) return undefined;
    const d = new Date();
    d.setDate(d.getDate() + dto.pruningFrequency);
    return d;
  }
}
