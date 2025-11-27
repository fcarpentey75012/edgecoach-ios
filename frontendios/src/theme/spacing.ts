/**
 * Espacements de l'application EdgeCoach
 * Système de spacing cohérent basé sur une base de 4px
 */

export const spacing = {
  // Espacements de base
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  '2xl': 48,
  '3xl': 64,

  // Alias sémantiques
  none: 0,
  hairline: 1,

  // Padding pour les conteneurs
  container: {
    horizontal: 16,
    vertical: 16,
  },

  // Padding pour les cartes
  card: {
    padding: 16,
    gap: 12,
  },

  // Spacing pour les formulaires
  form: {
    gap: 16,
    labelGap: 8,
  },

  // Border radius
  borderRadius: {
    none: 0,
    sm: 4,
    md: 8,
    lg: 12,
    xl: 16,
    full: 9999,
  },
};

export type Spacing = typeof spacing;
