/**
 * Composant wrapper pour les widgets du dashboard
 * Gère le drag & drop, l'affichage et les actions de personnalisation
 */

import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Animated,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { colors, spacing, typography } from '../../theme';

export type WidgetSize = 'small' | 'medium' | 'large' | 'full';

export interface WidgetConfig {
  id: string;
  type: WidgetType;
  title: string;
  size: WidgetSize;
  visible: boolean;
  order: number;
}

export type WidgetType =
  | 'weekly-summary'
  | 'weekly-chart'
  | 'sport-cards'
  | 'sport-distribution'
  | 'upcoming-sessions'
  | 'coach-insight';

interface DashboardWidgetProps {
  config: WidgetConfig;
  isEditMode: boolean;
  onToggleVisibility?: (id: string) => void;
  onMoveUp?: (id: string) => void;
  onMoveDown?: (id: string) => void;
  children: React.ReactNode;
}

const DashboardWidget: React.FC<DashboardWidgetProps> = ({
  config,
  isEditMode,
  onToggleVisibility,
  onMoveUp,
  onMoveDown,
  children,
}) => {
  if (!config.visible && !isEditMode) {
    return null;
  }

  return (
    <Animated.View
      style={[
        styles.container,
        !config.visible && styles.containerHidden,
        isEditMode && styles.containerEditMode,
      ]}
    >
      {/* Header du widget en mode édition */}
      {isEditMode && (
        <View style={styles.editHeader}>
          <View style={styles.editTitleContainer}>
            <Icon name="menu" size={18} color={colors.neutral.gray[400]} />
            <Text style={styles.editTitle}>{config.title}</Text>
          </View>
          <View style={styles.editActions}>
            <TouchableOpacity
              style={styles.editButton}
              onPress={() => onMoveUp?.(config.id)}
            >
              <Icon name="chevron-up" size={18} color={colors.neutral.gray[500]} />
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.editButton}
              onPress={() => onMoveDown?.(config.id)}
            >
              <Icon name="chevron-down" size={18} color={colors.neutral.gray[500]} />
            </TouchableOpacity>
            <TouchableOpacity
              style={[
                styles.editButton,
                config.visible ? styles.visibleButton : styles.hiddenButton,
              ]}
              onPress={() => onToggleVisibility?.(config.id)}
            >
              <Icon
                name={config.visible ? 'eye' : 'eye-off'}
                size={18}
                color={config.visible ? colors.primary[500] : colors.neutral.gray[400]}
              />
            </TouchableOpacity>
          </View>
        </View>
      )}

      {/* Contenu du widget */}
      <View style={[styles.content, !config.visible && styles.contentHidden]}>
        {children}
      </View>
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  container: {
    marginBottom: spacing.md,
  },
  containerHidden: {
    opacity: 0.5,
  },
  containerEditMode: {
    borderWidth: 2,
    borderColor: colors.primary[200],
    borderRadius: spacing.borderRadius.lg,
    borderStyle: 'dashed',
  },
  editHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: colors.primary[50],
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    borderTopLeftRadius: spacing.borderRadius.lg - 2,
    borderTopRightRadius: spacing.borderRadius.lg - 2,
  },
  editTitleContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  editTitle: {
    ...typography.styles.caption,
    color: colors.secondary[700],
    fontWeight: '600',
  },
  editActions: {
    flexDirection: 'row',
    gap: spacing.xs,
  },
  editButton: {
    padding: spacing.xs,
    borderRadius: spacing.borderRadius.sm,
    backgroundColor: colors.neutral.white,
  },
  visibleButton: {
    backgroundColor: colors.primary[100],
  },
  hiddenButton: {
    backgroundColor: colors.neutral.gray[100],
  },
  content: {
    // Le contenu est rendu par les enfants
  },
  contentHidden: {
    opacity: 0.4,
  },
});

export default DashboardWidget;
