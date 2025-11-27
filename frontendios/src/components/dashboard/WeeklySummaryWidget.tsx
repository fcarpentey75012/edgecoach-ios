/**
 * Widget résumé de la semaine
 * Affiche les stats clés avec barre de progression vers l'objectif
 */

import React, { useMemo } from 'react';
import {
  View,
  Text,
  StyleSheet,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { colors, spacing, typography } from '../../theme';
import { WeeklySummaryData, dashboardService } from '../../services';

interface WeeklySummaryWidgetProps {
  weeklyData: WeeklySummaryData | null;
}

const WeeklySummaryWidget: React.FC<WeeklySummaryWidgetProps> = ({
  weeklyData,
}) => {
  // Formater la période de la semaine
  const weekPeriod = useMemo(() => {
    if (!weeklyData) return 'Cette semaine';

    const start = new Date(weeklyData.weekStart);
    const end = new Date(weeklyData.weekEnd);

    const formatDay = (date: Date) =>
      date.toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' });

    return `${formatDay(start)} - ${formatDay(end)}`;
  }, [weeklyData]);

  const stats = [
    {
      icon: 'time-outline',
      value: dashboardService.formatDuration(weeklyData?.summary.totalDuration || 0),
      label: 'Temps total',
      color: colors.primary[500],
    },
    {
      icon: 'layers-outline',
      value: weeklyData?.summary.sessionsCount || 0,
      label: 'Séances',
      color: colors.sports.triathlon,
    },
    {
      icon: 'navigate-outline',
      value: dashboardService.formatDistance(weeklyData?.summary.totalDistance || 0),
      label: 'Distance',
      color: colors.sports.running,
    },
  ];

  const progressPercentage = weeklyData?.weekProgress?.percentage || 0;
  const hasTarget = weeklyData?.weekProgress && weeklyData.weekProgress.targetDuration > 0;

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <View style={styles.titleContainer}>
          <Icon name="calendar-outline" size={20} color={colors.primary[500]} />
          <Text style={styles.title}>Résumé semaine</Text>
        </View>
        <Text style={styles.period}>{weekPeriod}</Text>
      </View>

      {/* Stats principales */}
      <View style={styles.statsRow}>
        {stats.map((stat, index) => (
          <View key={stat.label} style={styles.statItem}>
            <View style={[styles.statIconContainer, { backgroundColor: stat.color + '15' }]}>
              <Icon name={stat.icon} size={18} color={stat.color} />
            </View>
            <Text style={[styles.statValue, { color: stat.color }]}>{stat.value}</Text>
            <Text style={styles.statLabel}>{stat.label}</Text>
          </View>
        ))}
      </View>

      {/* Stats secondaires */}
      <View style={styles.secondaryStats}>
        <View style={styles.secondaryStat}>
          <Icon name="trending-up-outline" size={14} color={colors.neutral.gray[400]} />
          <Text style={styles.secondaryLabel}>Dénivelé</Text>
          <Text style={styles.secondaryValue}>
            {weeklyData?.summary.totalElevation || 0} m
          </Text>
        </View>
        <View style={styles.secondaryDivider} />
        <View style={styles.secondaryStat}>
          <Icon name="flame-outline" size={14} color={colors.status.warning} />
          <Text style={styles.secondaryLabel}>Calories</Text>
          <Text style={styles.secondaryValue}>
            {weeklyData?.summary.totalCalories || 0} kcal
          </Text>
        </View>
      </View>

      {/* Barre de progression */}
      {hasTarget && (
        <View style={styles.progressSection}>
          <View style={styles.progressHeader}>
            <Text style={styles.progressLabel}>Objectif hebdomadaire</Text>
            <Text style={styles.progressPercent}>{progressPercentage}%</Text>
          </View>
          <View style={styles.progressBarBackground}>
            <View
              style={[
                styles.progressBarFill,
                {
                  width: `${Math.min(progressPercentage, 100)}%`,
                  backgroundColor:
                    progressPercentage >= 100
                      ? colors.status.success
                      : progressPercentage >= 70
                      ? colors.primary[500]
                      : colors.status.warning,
                },
              ]}
            />
          </View>
          <Text style={styles.progressDetails}>
            {dashboardService.formatDuration(weeklyData?.weekProgress?.achievedDuration || 0)}
            {' / '}
            {dashboardService.formatDuration(weeklyData?.weekProgress?.targetDuration || 0)}
          </Text>
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.md,
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.md,
  },
  titleContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  title: {
    ...typography.styles.label,
    color: colors.secondary[800],
  },
  period: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  statsRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginBottom: spacing.md,
  },
  statItem: {
    alignItems: 'center',
  },
  statIconContainer: {
    width: 36,
    height: 36,
    borderRadius: 18,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: spacing.xs,
  },
  statValue: {
    ...typography.styles.h3,
    fontSize: 20,
  },
  statLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    marginTop: 2,
  },
  secondaryStats: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.neutral.gray[50],
    borderRadius: spacing.borderRadius.md,
    paddingVertical: spacing.sm,
    paddingHorizontal: spacing.md,
    marginBottom: spacing.md,
  },
  secondaryStat: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  secondaryLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  secondaryValue: {
    ...typography.styles.caption,
    color: colors.secondary[700],
    fontWeight: '600',
  },
  secondaryDivider: {
    width: 1,
    height: 16,
    backgroundColor: colors.neutral.gray[200],
    marginHorizontal: spacing.md,
  },
  progressSection: {
    borderTopWidth: 1,
    borderTopColor: colors.neutral.gray[100],
    paddingTop: spacing.md,
  },
  progressHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.xs,
  },
  progressLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  progressPercent: {
    ...typography.styles.label,
    color: colors.primary[600],
  },
  progressBarBackground: {
    height: 8,
    backgroundColor: colors.neutral.gray[200],
    borderRadius: 4,
    overflow: 'hidden',
  },
  progressBarFill: {
    height: '100%',
    borderRadius: 4,
  },
  progressDetails: {
    ...typography.styles.caption,
    color: colors.neutral.gray[400],
    textAlign: 'center',
    marginTop: spacing.xs,
  },
});

export default WeeklySummaryWidget;
