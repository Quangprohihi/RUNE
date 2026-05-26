import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static TextStyle get heading => GoogleFonts.montserratAlternates(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryBlue,
  );

  static TextStyle get title => GoogleFonts.montserratAlternates(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get body => GoogleFonts.montserratAlternates(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle get label => GoogleFonts.montserratAlternates(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle get muted => GoogleFonts.montserratAlternates(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );
}
