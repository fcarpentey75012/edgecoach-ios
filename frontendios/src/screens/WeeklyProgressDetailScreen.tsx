/**
 * Écran de détails de la progression hebdomadaire
 */

import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Dimensions,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { RootStackParamList } from '../navigation/types';
import { colors, spacing, typography } from '../theme';
import { dashboardService, DisciplineType } from '../services';

type Props = NativeStackScreenProps<RootStackParamList, 'WeeklyProgressDetail'>;

const { width: screenWidth } = Dimensions.get('window');

const WeeklyProgressDetailScreen: React.FC<Props> = ({ route }) => {
  const { weeklyData } = route.params;

  // Calculer les pourcentages pour le graphique circulaire
  const totalDuration = weeklyData?.summary.totalDuration || 0;
  const disciplines: { key: DisciplineType; color: string; icon: string; label: string }[] = [
    { key: 'cyclisme', color: colors.sports.cycling, icon: 'bicycle', label: 'Vélo' },
    { key: 'course', color: colors.sports.running, icon: 'walk', label: 'Course' },
    { key: 'natation', color: colors.sports.swimming, icon: 'water', label: 'Natation' },
    { key: 'autre', color: colors.neutral.gray[400], icon: 'fitness', label: 'Autre' },
  ];

  const getDisciplinePercentage = (key: DisciplineType): number => {
    if (!weeklyData || totalDuration === 0) return 0;
    return Math.round((weeklyData.byDiscipline[key].duration / totalDuration) * 100);
  };

  // Formater la période de la semaine
  const formatWeekPeriod = () => {
    if (!weeklyData) return 'Cette semaine';
    const start = new Date(weeklyData.weekStart);
    const end = new Date(weeklyData.weekEnd);
    const options: Intl.DateTimeFormatOptions = { day: 'numeric', month: 'short' };
    return `${start.toLocaleDateString('fr-FR', options)} - ${end.toLocaleDateString('fr-FR', options)}`;
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      {/* En-tête de la période */}
      <View style={styles.periodHeader}>
        <Icon name="calendar-outline" size={20} color={colors.primary[500]} />
        <Text style={styles.periodText}>{formatWeekPeriod()}</Text>
      </View>

      {/* Statistiques principales */}
      <View style={styles.mainStatsCard}>
        <Text style={styles.cardTitle}>Résumé de la semaine</Text>

        <View style={styles.statsGrid}>
          <View style={styles.statItem}>
            <View style={[styles.statIconContainer, { backgroundColor: colors.primary[50] }]}>
              <Icon name="time-outline" size={24} color={colors.primary[500]} />
            </View>
            <Text style={styles.statValue}>
              {dashboardService.formatDuration(weeklyData?.summary.totalDuration || 0)}
            </Text>
            <Text style={styles.statLabel}>Temps total</Text>
          </View>

          <View style={styles.statItem}>
            <View style={[styles.statIconContainer, { backgroundColor: colors.sports.running + '20' }]}>
              <Icon name="flag-outline" size={24} color={colors.sports.running} />
            </View>
            <Text style={styles.statValue}>
              {weeklyData?.summary.sessionsCount || 0}
            </Text>
            <Text style={styles.statLabel}>Séances</Text>
          </View>

          <View style={styles.statItem}>
            <View style={[styles.statIconContainer, { backgroundColor: colors.sports.cycling + '20' }]}>
              <Icon name="navigate-outline" size={24} color={colors.sports.cycling} />
            </View>
            <Text style={styles.statValue}>
              {dashboardService.formatDistance(weeklyData?.summary.totalDistance || 0)}
            </Text>
            <Text style={styles.statLabel}>Distance</Text>
          </View>

          <View style={styles.statItem}>
            <View style={[styles.statIconContainer, { backgroundColor: colors.sports.swimming + '20' }]}>
              <Icon name="flame-outline" size={24} color={colors.sports.swimming} />
            </View>
            <Text style={styles.statValue}>
              {weeklyData?.summary.totalCalories || 0}
            </Text>
            <Text style={styles.statLabel}>Calories</Text>
          </View>

          <View style={styles.statItem}>
            <View style={[styles.statIconContainer, { backgroundColor: colors.neutral.gray[100] }]}>
              <Icon name="trending-up-outline" size={24} color={colors.neutral.gray[600]} />
            </View>
            <Text style={styles.statValue}>
              {weeklyData?.summary.totalElevation || 0} m
            </Text>
            <Text style={styles.statLabel}>Dénivelé</Text>
          </View>
        </View>
      </View>

      {/* Objectif hebdomadaire */}
      {weeklyData?.weekProgress && weeklyData.weekProgress.targetDuration > 0 && (
        <View style={styles.goalCard}>
          <View style={styles.goalHeader}>
            <Icon name="trophy-outline" size={24} color={colors.primary[500]} />
            <Text style={styles.cardTitle}>Objectif hebdomadaire</Text>
          </View>

          <View style={styles.goalContent}>
            <View style={styles.goalProgressCircle}>
              <Text style={styles.goalPercentage}>{weeklyData.weekProgress.percentage}%</Text>
            </View>
            <View style={styles.goalDetails}>
              <Text style={styles.goalText}>
                <Text style={styles.goalHighlight}>
                  {dashboardService.formatDuration(weeklyData.weekProgress.achievedDuration)}
                </Text>
                {' '}réalisé sur{' '}
                <Text style={styles.goalHighlight}>
                  {dashboardService.formatDuration(weeklyData.weekProgress.targetDuration)}
                </Text>
              </Text>
              <View style={styles.goalProgressBar}>
                <View
                  style={[
                    styles.goalProgressFill,
                    { width: `${Math.min(weeklyData.weekProgress.percentage, 100)}%` },
                  ]}
                />
              </View>
            </View>
          </View>
        </View>
      )}

      {/* Répartition par discipline */}
      <View style={styles.breakdownCard}>
        <Text style={styles.cardTitle}>Répartition par discipline</Text>

        {totalDuration > 0 ? (
          <>
            {/* Barre de répartition horizontale */}
            <View style={styles.horizontalBar}>
              {disciplines.map((d) => {
                const duration = weeklyData?.byDiscipline[d.key].duration || 0;
                if (duration === 0) return null;
                return (
                  <View
                    key={d.key}
                    style={[
                      styles.horizontalBarSegment,
                      {
                        flex: duration,
                        backgroundColor: d.color,
                      },
                    ]}
                  />
                );
              })}
            </View>

            {/* Détails par discipline */}
            <View style={styles.disciplinesList}>
              {disciplines.map((d) => {
                const stats = weeklyData?.byDiscipline[d.key];
                if (!stats || stats.count === 0) return null;

                const percentage = getDisciplinePercentage(d.key);

                return (
                  <View key={d.key} style={styles.disciplineItem}>
                    <View style={styles.disciplineHeader}>
                      <View style={[styles.disciplineIcon, { backgroundColor: d.color + '20' }]}>
                        <Icon name={d.icon} size={20} color={d.color} />
                      </View>
                      <View style={styles.disciplineInfo}>
                        <Text style={styles.disciplineName}>{d.label}</Text>
                        <Text style={styles.disciplineCount}>
                          {stats.count} séance{stats.count > 1 ? 's' : ''}
                        </Text>
                      </View>
                      <View style={styles.disciplinePercentage}>
                        <Text style={[styles.percentageText, { color: d.color }]}>{percentage}%</Text>
                      </View>
                    </View>

                    <View style={styles.disciplineStats}>
                      <View style={styles.disciplineStat}>
                        <Icon name="time-outline" size={14} color={colors.neutral.gray[400]} />
                        <Text style={styles.disciplineStatText}>
                          {dashboardService.formatDuration(stats.duration)}
                        </Text>
                      </View>
                      <View style={styles.disciplineStat}>
                        <Icon name="navigate-outline" size={14} color={colors.neutral.gray[400]} />
                        <Text style={styles.disciplineStatText}>
                          {dashboardService.formatDistance(stats.distance, d.key)}
                        </Text>
                      </View>
                    </View>
                  </View>
                );
              })}
            </View>
          </>
        ) : (
          <View style={styles.emptyState}>
            <Icon name="analytics-outline" size={48} color={colors.neutral.gray[300]} />
            <Text style={styles.emptyStateText}>
              Aucune activité cette semaine
            </Text>
            <Text style={styles.emptyStateSubtext}>
              Commencez à enregistrer vos séances pour voir vos statistiques ici.
            </Text>
          </View>
        )}
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.light.background,
  },
  content: {
    padding: spacing.container.horizontal,
    paddingBottom: spacing.xl,
  },
  periodHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.sm,
    marginBottom: spacing.lg,
    paddingVertical: spacing.sm,
    backgroundColor: colors.primary[50],
    borderRadius: spacing.borderRadius.md,
  },
  periodText: {
    ...typography.styles.label,
    color: colors.primary[600],
  },
  mainStatsCard: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.lg,
    marginBottom: spacing.md,
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  cardTitle: {
    ...typography.styles.h4,
    color: colors.secondary[800],
    marginBottom: spacing.md,
  },
  statsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    gap: spacing.md,
  },
  statItem: {
    width: (screenWidth - spacing.container.horizontal * 2 - spacing.lg * 2 - spacing.md) / 2 - spacing.md / 2,
    alignItems: 'center',
    paddingVertical: spacing.md,
    backgroundColor: colors.neutral.gray[50],
    borderRadius: spacing.borderRadius.md,
  },
  statIconContainer: {
    width: 48,
    height: 48,
    borderRadius: 24,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: spacing.sm,
  },
  statValue: {
    ...typography.styles.h3,
    color: colors.secondary[800],
  },
  statLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    marginTop: spacing.xs,
  },
  goalCard: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.lg,
    marginBottom: spacing.md,
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  goalHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: spacing.md,
  },
  goalContent: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.lg,
  },
  goalProgressCircle: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: colors.primary[50],
    borderWidth: 4,
    borderColor: colors.primary[500],
    justifyContent: 'center',
    alignItems: 'center',
  },
  goalPercentage: {
    ...typography.styles.h3,
    color: colors.primary[500],
  },
  goalDetails: {
    flex: 1,
  },
  goalText: {
    ...typography.styles.body,
    color: colors.neutral.gray[600],
    marginBottom: spacing.sm,
  },
  goalHighlight: {
    color: colors.secondary[800],
    fontWeight: typography.fontWeights.semiBold as any,
  },
  goalProgressBar: {
    height: 8,
    backgroundColor: colors.neutral.gray[200],
    borderRadius: 4,
    overflow: 'hidden',
  },
  goalProgressFill: {
    height: '100%',
    backgroundColor: colors.primary[500],
    borderRadius: 4,
  },
  breakdownCard: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.lg,
    marginBottom: spacing.md,
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  horizontalBar: {
    flexDirection: 'row',
    height: 12,
    borderRadius: 6,
    overflow: 'hidden',
    gap: 2,
    marginBottom: spacing.lg,
  },
  horizontalBarSegment: {
    borderRadius: 6,
  },
  disciplinesList: {
    gap: spacing.md,
  },
  disciplineItem: {
    backgroundColor: colors.neutral.gray[50],
    borderRadius: spacing.borderRadius.md,
    padding: spacing.md,
  },
  disciplineHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing.sm,
  },
  disciplineIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: spacing.md,
  },
  disciplineInfo: {
    flex: 1,
  },
  disciplineName: {
    ...typography.styles.label,
    color: colors.secondary[800],
  },
  disciplineCount: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  disciplinePercentage: {
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.sm,
  },
  percentageText: {
    ...typography.styles.label,
  },
  disciplineStats: {
    flexDirection: 'row',
    gap: spacing.lg,
    paddingLeft: 56, // Aligner avec le texte après l'icône
  },
  disciplineStat: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  disciplineStatText: {
    ...typography.styles.caption,
    color: colors.neutral.gray[600],
  },
  emptyState: {
    alignItems: 'center',
    paddingVertical: spacing.xl,
  },
  emptyStateText: {
    ...typography.styles.body,
    color: colors.neutral.gray[500],
    marginTop: spacing.md,
    textAlign: 'center',
  },
  emptyStateSubtext: {
    ...typography.styles.caption,
    color: colors.neutral.gray[400],
    marginTop: spacing.xs,
    textAlign: 'center',
  },
});

export default WeeklyProgressDetailScreen;
