import { stubsRoot } from '@adonisjs/core';
import { args, BaseCommand } from '@adonisjs/core/ace';
import { ESLint } from 'eslint';

import type { CommandOptions } from '@adonisjs/core/types/ace';

export default class MakeModule extends BaseCommand {
  static commandName = 'make:module';
  static description = 'Create a new module with controller, service, validator, and route';

  static options: CommandOptions = {};

  @args.string({ description: 'Name of the module' })
  declare name: string;
  protected stubPaths: string[] = [
    'make/module/controller.stub',
    'make/module/route.stub',
    'make/module/service.stub',
    'make/module/validator.stub',
  ];

  async run() {
    const codeModes = await this.createCodemods();
    const project = await codeModes.getTsMorphProject();
    if (!project) {
      this.logger.error('Failed to get transformer');
      return;
    }
    // create modules with controller, service, validator, and route
    const stubsResponse = await Promise.allSettled(
      this.stubPaths.map((stubPath) => {
        return codeModes.makeUsingStub(stubsRoot, stubPath, {
          name: this.name,
        });
      })
    );

    if (stubsResponse.some((response) => response.status === 'rejected')) {
      this.logger.error('Failed to create module');
      // delete all created files

      return;
    }

    const createdFiles = stubsResponse
      .filter((res) => res.status === 'fulfilled')
      .map((res) => res.value.relativeFileName);

    try {
      // Run ESLint on created files
      const eslint = new ESLint({
        fix: true,
        overrideConfigFile: this.app.makePath('eslint.config.mjs'),
      });
      const results = await eslint.lintFiles(createdFiles);
      await ESLint.outputFixes(results);
    } catch (error) {
      this.logger.warning('ESLint encountered an error: ', error);
    }

    // Register the route in start/routes.ts
    const routeFile = project.getSourceFileOrThrow('start/routes.ts');
    const importDeclarations = routeFile.getImportDeclarations();
    const insertIndex = importDeclarations.length;

    const moduleName = this.name;
    const importPath = `#modules/${moduleName}/${moduleName}.route`;
    // before inserting check if import already exists
    const existingImport = importDeclarations.find(
      (declaration) => declaration.getModuleSpecifierValue() === importPath
    );
    if (!existingImport) {
      routeFile.insertImportDeclaration(insertIndex + 1, {
        moduleSpecifier: importPath,
      });
      await routeFile.save();
      this.logger.success(`Module '${this.name}' created successfully.`);
    } else {
      this.logger.info(`Module '${this.name}' already imported in start/routes.ts.`);
    }
  }
}
