/**
 * Export centralisé du thème EdgeCoach
 */

export { colors } from './colors';
export { typography } from './typography';
export { spacing } from './spacing';

import { colors } from './colors';
import { typography } from './typography';
import { spacing } from './spacing';

export const theme = {
  colors,
  typography,
  spacing,
};

export type Theme = typeof theme;

// Helper pour obtenir les couleurs selon le mode (clair/sombre)
export const getThemeColors = (isDark: boolean) => {
  return isDark ? colors.dark : colors.light;
};
