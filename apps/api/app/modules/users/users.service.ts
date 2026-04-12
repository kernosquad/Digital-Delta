import db from '@adonisjs/lucid/services/db';

import type { UpdateRoleType, UpdateStatusType } from './users.validator.js';
import type { HttpContext } from '@adonisjs/core/http';

import User from '#models/user';

export class UsersService {
  async index({ request, response }: HttpContext) {
    const page = request.input('page', 1);
    const perPage = request.input('per_page', 25);
    const role = request.input('role');
    const status = request.input('status', 'active');
    const query = User.query().whereNull('deleted_at').where('status', status);
    if (role) query.where('role', role);
    const users = await query.paginate(page, perPage);
    return response.sendFormatted(users);
  }

  async show({ params, response }: HttpContext) {
    const user = await User.query().where('id', params.id).whereNull('deleted_at').firstOrFail();
    return response.sendFormatted(user);
  }

  async updateRole({ params, auth, response }: HttpContext, payload: UpdateRoleType) {
    const user = await User.findOrFail(params.id);
    const actor = auth.user!;
    const oldRole = user.role;
    await user.merge({ role: payload.role as any }).save();
    await db.table('auth_logs').insert({
      user_id: user.id,
      event_type: 'role_change',
      payload: JSON.stringify({ old: oldRole, new: payload.role, changed_by: actor.id }),
      event_hash: '',
      created_at: new Date(),
    });
    return response.sendFormatted({ role: user.role }, 'Role updated');
  }

  async updateStatus({ params, response }: HttpContext, payload: UpdateStatusType) {
    const user = await User.findOrFail(params.id);
    await user.merge({ status: payload.status as any }).save();
    return response.sendFormatted({ status: user.status }, 'Status updated');
  }
}
