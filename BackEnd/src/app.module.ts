/**
 * @file app.module.ts
 * @description Módulo raíz vacío de NestJS — el proyecto resuelve controllers,
 * services y use cases vía Inversify (`core/container.ts`), no via decoradores
 * `@Module`. NestJS solo se usa por la infraestructura HTTP (NestFactory +
 * adaptador Express) en `main.ts`. Si en el futuro se migrase a módulos
 * NestJS nativos, este shell sería el punto de entrada.
 * @module Core
 * @layer Presentation
 */

import { Module } from '@nestjs/common';

@Module({
  imports:     [],
  controllers: [],
  providers:   [],
})
export class AppModule {}
