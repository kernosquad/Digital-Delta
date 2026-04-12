import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primarySurfaceDefault = Color(0xFF05944f);
  static const Color primarySurfaceLight = Color(0xFF00bf63);
  static const Color primarySurfaceDark = Color(0xFF007A43);

  // Danger
  static const Color dangerSurfaceDefault = Color(0xFFF1113E);
  static const Color dangerSurfaceLight = Color(0xFFFF6B87);

  // Warning
  static const Color warningSurfaceDefault = Color(0xFFFFAB00);

  // Background
  static const Color colorBackground = Color(0xFFF8F9FE);
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  // Text
  static const Color primaryTextDefault = Color(0xFF1A1A2E);
  static const Color secondaryTextDefault = Color(0xFF6B7280);
  static const Color disabledTextDefault = Color(0xFFD1D5DB);

  // Border
  static const Color borderDefault = Color(0xFFE5E7EB);
  static const Color borderActive = Color(0xFF00B262);

  // Overlay
  static const Color overlayDark = Color(0x80000000);
  static const Color overlayLight = Color(0x33FFFFFF);

  // ── Semantic status colors ─────────────────────────────────────────────────
  static const Color statusOnline  = primarySurfaceDefault;   // green
  static const Color statusOffline = dangerSurfaceDefault;    // red
  static const Color statusIdle    = Color(0xFF64748B);       // slate
  static const Color statusPending = warningSurfaceDefault;   // amber

  // ── Priority taxonomy (P0 – P3) ────────────────────────────────────────────
  static const Color priorityP0 = dangerSurfaceDefault;       // critical — red
  static const Color priorityP1 = warningSurfaceDefault;      // high     — amber
  static const Color priorityP2 = Color(0xFF1565C0);          // standard — blue
  static const Color priorityP3 = Color(0xFF64748B);          // low      — slate

  // ── Info (secondary blue) ──────────────────────────────────────────────────
  static const Color infoSurface = Color(0xFFEFF6FF);         // blue-50
  static const Color infoBorder  = Color(0xFFBFDBFE);         // blue-200
  static const Color infoText    = Color(0xFF1D4ED8);         // blue-700

  // ── Surface tints (light backgrounds for chips / inline callouts) ──────────
  static const Color dangerSurfaceTint   = Color(0xFFFEE2E2); // red-100
  static const Color warningSurfaceTint  = Color(0xFFFEF3C7); // amber-100
  static const Color primarySurfaceTint  = Color(0xFFDCFCE7); // green-100
  static const Color infoSurfaceTint     = Color(0xFFDBEAFE); // blue-100
  static const Color neutralSurfaceTint  = Color(0xFFF1F5F9); // slate-100

  // ── Map node type colors ───────────────────────────────────────────────────
  static const Color nodeCommand    = Color(0xFF1A237E);      // deep blue
  static const Color nodeReliefCamp = primarySurfaceDark;     // dark green
  static const Color nodeHospital   = dangerSurfaceDefault;   // red
  static const Color nodeSupplyDrop = warningSurfaceDefault;  // amber
  static const Color nodeDroneBase  = Color(0xFF4A148C);      // deep purple
  static const Color nodeWaypoint   = Color(0xFF546E7A);      // blue-grey

  // ── Role colors ────────────────────────────────────────────────────────────
  static const Color roleCommander    = warningSurfaceDefault; // amber
  static const Color roleSupplyMgr    = Color(0xFF1565C0);    // blue
  static const Color roleDroneOp      = Color(0xFF283593);    // indigo
  static const Color roleVolunteer    = primarySurfaceDefault; // green
  static const Color roleSyncAdmin    = dangerSurfaceDefault;  // red
}
