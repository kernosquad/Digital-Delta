import { configApp } from '@adonisjs/eslint-config';
import { addonConfig } from '@repo/eslint-config/addon';

export default [...configApp(), ...addonConfig];
