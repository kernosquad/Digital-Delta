import { BaseSeeder } from '@adonisjs/lucid/seeders'

import User from '#models/user'

/**
 * Seed one user per role + a super-admin.
 * Passwords are all "Password123" (change in production via env).
 * All users are pre-verified / active so the hackathon demo works without email flows.
 */
export default class UserSeeder extends BaseSeeder {
  async run() {
    await User.createMany([
      {
        name: 'Admin (Sync)',
        email: 'admin@digitaldelta.io',
        phone: '+8801711000000',
        password: '12345678',
        role: 'sync_admin',
        status: 'active',
      },
      {
        name: 'Camp Commander Rahim',
        email: 'commander@digitaldelta.io',
        phone: '+8801711000001',
        password: '12345678',
        role: 'camp_commander',
        status: 'active',
      },
      {
        name: 'Supply Manager Karim',
        email: 'supply@digitaldelta.io',
        phone: '+8801711000002',
        password: '12345678',
        role: 'supply_manager',
        status: 'active',
      },
      {
        name: 'Drone Operator Jamal',
        email: 'drone@digitaldelta.io',
        phone: '+8801711000003',
        password: '12345678',
        role: 'drone_operator',
        status: 'active',
      },
      {
        name: 'Field Volunteer Sadia',
        email: 'volunteer@digitaldelta.io',
        phone: '+8801711000004',
        password: '12345678',
        role: 'field_volunteer',
        status: 'active',
      },
    ])
  }
}
