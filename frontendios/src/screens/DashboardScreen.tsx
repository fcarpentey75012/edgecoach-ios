/**
 * Écran Dashboard - Page d'accueil
 */

import React, { useEffect, useState, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  ActivityIndicator,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useAuth } from '../contexts/AuthContext';
import { RootStackParamList } from '../navigation/types';
import { colors, spacing, typography } from '../theme';
import { dashboardService, WeeklySummaryData, DisciplineType } from '../services';

type DashboardNavigationProp = NativeStackNavigationProp<RootStackParamList>;

const DashboardScreen: React.FC = () => {
  const navigation = useNavigation<DashboardNavigationProp>();
  const { user } = useAuth();
  const [refreshing, setRefreshing] = useState(false);
  const [loading, setLoading] = useState(true);
  const [weeklyData, setWeeklyData] = useState<WeeklySummaryData | null>(null);

  // Charger les données du dashboard
  const loadDashboardData = useCallback(async () => {
    if (!user?.id) return;

    try {
      const result = await dashboardService.getWeeklySummary(user.id);
      if (result.success && result.data) {
        setWeeklyData(result.data);
      } else {
        // Utiliser les données vides en cas d'erreur
        setWeeklyData(dashboardService.getEmptyWeeklySummary());
      }
    } catch (error) {
      console.error('Erreur chargement dashboard:', error);
      setWeeklyData(dashboardService.getEmptyWeeklySummary());
    } finally {
      setLoading(false);
    }
  }, [user?.id]);

  useEffect(() => {
    loadDashboardData();
  }, [loadDashboardData]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await loadDashboardData();
    setRefreshing(false);
  }, [loadDashboardData]);

  // Obtenir le message de salutation selon l'heure
  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  };

  // Navigation vers les séances d'une discipline
  const navigateToDiscipline = (discipline: DisciplineType) => {
    navigation.navigate('DisciplineSessions', {
      discipline,
      weekStart: weeklyData?.weekStart,
    });
  };

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.content}
      refreshControl={
        <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
      }
    >
      {/* Welcome Section */}
      <View style={styles.welcomeSection}>
        <Text style={styles.greeting}>
          {getGreeting()}, {user?.firstName || 'Athlète'} 👋
        </Text>
        <Text style={styles.welcomeSubtitle}>
          Prêt pour votre entraînement ?
        </Text>
      </View>

      {/* Quick Actions - Stats par sport */}
      <View style={styles.quickActions}>
        <TouchableOpacity
          style={styles.quickActionCard}
          onPress={() => navigateToDiscipline('cyclisme')}
          activeOpacity={0.7}
        >
          <View style={[styles.iconContainer, { backgroundColor: colors.sports.cycling + '20' }]}>
            <Icon name="bicycle" size={28} color={colors.sports.cycling} />
          </View>
          <Text style={styles.quickActionTitle}>Vélo</Text>
          <Text style={styles.quickActionSubtitle}>
            {weeklyData?.byDiscipline.cyclisme.count || 0} séance{(weeklyData?.byDiscipline.cyclisme.count || 0) > 1 ? 's' : ''}
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.quickActionCard}
          onPress={() => navigateToDiscipline('course')}
          activeOpacity={0.7}
        >
          <View style={[styles.iconContainer, { backgroundColor: colors.sports.running + '20' }]}>
            <Icon name="walk" size={28} color={colors.sports.running} />
          </View>
          <Text style={styles.quickActionTitle}>Course</Text>
          <Text style={styles.quickActionSubtitle}>
            {weeklyData?.byDiscipline.course.count || 0} séance{(weeklyData?.byDiscipline.course.count || 0) > 1 ? 's' : ''}
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.quickActionCard}
          onPress={() => navigateToDiscipline('natation')}
          activeOpacity={0.7}
        >
          <View style={[styles.iconContainer, { backgroundColor: colors.sports.swimming + '20' }]}>
            <Icon name="water" size={28} color={colors.sports.swimming} />
          </View>
          <Text style={styles.quickActionTitle}>Natation</Text>
          <Text style={styles.quickActionSubtitle}>
            {weeklyData?.byDiscipline.natation.count || 0} séance{(weeklyData?.byDiscipline.natation.count || 0) > 1 ? 's' : ''}
          </Text>
        </TouchableOpacity>
      </View>

      {/* Catégorie Autre (si séances présentes) */}
      {weeklyData?.byDiscipline.autre && weeklyData.byDiscipline.autre.count > 0 && (
        <TouchableOpacity
          style={styles.otherCard}
          onPress={() => navigateToDiscipline('autre')}
          activeOpacity={0.7}
        >
          <View style={[styles.otherIconContainer, { backgroundColor: colors.neutral.gray[200] }]}>
            <Icon name="fitness" size={24} color={colors.neutral.gray[600]} />
          </View>
          <View style={styles.otherContent}>
            <Text style={styles.otherTitle}>Autre</Text>
            <Text style={styles.otherSubtitle}>
              {weeklyData.byDiscipline.autre.count} séance{weeklyData.byDiscipline.autre.count > 1 ? 's' : ''}
            </Text>
          </View>
          <Icon name="chevron-forward" size={20} color={colors.neutral.gray[400]} />
        </TouchableOpacity>
      )}

      {/* Weekly Progress */}
      <View style={styles.section}>
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>Progression de la semaine</Text>
          <TouchableOpacity
            onPress={() => navigation.navigate('WeeklyProgressDetail', { weeklyData })}
            activeOpacity={0.7}
          >
            <Text style={styles.seeMoreText}>Voir plus</Text>
          </TouchableOpacity>
        </View>
        <TouchableOpacity
          style={styles.progressCard}
          onPress={() => navigation.navigate('WeeklyProgressDetail', { weeklyData })}
          activeOpacity={0.7}
        >
          {/* Ligne principale : Temps, Séances, Distance */}
          <View style={styles.progressRow}>
            <View style={styles.progressItem}>
              <View style={styles.progressIconContainer}>
                <Icon name="time-outline" size={20} color={colors.primary[500]} />
              </View>
              <Text style={styles.progressValue}>
                {dashboardService.formatDuration(weeklyData?.summary.totalDuration || 0)}
              </Text>
              <Text style={styles.progressLabel}>Temps</Text>
            </View>
            <View style={styles.progressDivider} />
            <View style={styles.progressItem}>
              <View style={styles.progressIconContainer}>
                <Icon name="flag-outline" size={20} color={colors.primary[500]} />
              </View>
              <Text style={styles.progressValue}>
                {weeklyData?.summary.sessionsCount || 0}
              </Text>
              <Text style={styles.progressLabel}>Séances</Text>
            </View>
            <View style={styles.progressDivider} />
            <View style={styles.progressItem}>
              <View style={styles.progressIconContainer}>
                <Icon name="navigate-outline" size={20} color={colors.primary[500]} />
              </View>
              <Text style={styles.progressValue}>
                {dashboardService.formatDistance(weeklyData?.summary.totalDistance || 0)}
              </Text>
              <Text style={styles.progressLabel}>Distance</Text>
            </View>
          </View>

          {/* Ligne secondaire : Calories, Dénivelé */}
          <View style={styles.progressRowSecondary}>
            <View style={styles.progressItemSecondary}>
              <Icon name="flame-outline" size={16} color={colors.sports.running} />
              <Text style={styles.progressValueSecondary}>
                {weeklyData?.summary.totalCalories || 0} kcal
              </Text>
            </View>
            <View style={styles.progressItemSecondary}>
              <Icon name="trending-up-outline" size={16} color={colors.sports.cycling} />
              <Text style={styles.progressValueSecondary}>
                {weeklyData?.summary.totalElevation || 0} m D+
              </Text>
            </View>
          </View>

          {/* Répartition par sport */}
          {weeklyData && weeklyData.summary.sessionsCount > 0 && (
            <View style={styles.sportBreakdown}>
              <Text style={styles.sportBreakdownTitle}>Répartition</Text>
              <View style={styles.sportBreakdownBar}>
                {weeklyData.byDiscipline.cyclisme.duration > 0 && (
                  <View
                    style={[
                      styles.sportBreakdownSegment,
                      {
                        flex: weeklyData.byDiscipline.cyclisme.duration,
                        backgroundColor: colors.sports.cycling,
                      },
                    ]}
                  />
                )}
                {weeklyData.byDiscipline.course.duration > 0 && (
                  <View
                    style={[
                      styles.sportBreakdownSegment,
                      {
                        flex: weeklyData.byDiscipline.course.duration,
                        backgroundColor: colors.sports.running,
                      },
                    ]}
                  />
                )}
                {weeklyData.byDiscipline.natation.duration > 0 && (
                  <View
                    style={[
                      styles.sportBreakdownSegment,
                      {
                        flex: weeklyData.byDiscipline.natation.duration,
                        backgroundColor: colors.sports.swimming,
                      },
                    ]}
                  />
                )}
                {weeklyData.byDiscipline.autre.duration > 0 && (
                  <View
                    style={[
                      styles.sportBreakdownSegment,
                      {
                        flex: weeklyData.byDiscipline.autre.duration,
                        backgroundColor: colors.neutral.gray[400],
                      },
                    ]}
                  />
                )}
              </View>
              <View style={styles.sportBreakdownLegend}>
                {weeklyData.byDiscipline.cyclisme.duration > 0 && (
                  <View style={styles.legendItem}>
                    <View style={[styles.legendDot, { backgroundColor: colors.sports.cycling }]} />
                    <Text style={styles.legendText}>Vélo</Text>
                  </View>
                )}
                {weeklyData.byDiscipline.course.duration > 0 && (
                  <View style={styles.legendItem}>
                    <View style={[styles.legendDot, { backgroundColor: colors.sports.running }]} />
                    <Text style={styles.legendText}>Course</Text>
                  </View>
                )}
                {weeklyData.byDiscipline.natation.duration > 0 && (
                  <View style={styles.legendItem}>
                    <View style={[styles.legendDot, { backgroundColor: colors.sports.swimming }]} />
                    <Text style={styles.legendText}>Natation</Text>
                  </View>
                )}
                {weeklyData.byDiscipline.autre.duration > 0 && (
                  <View style={styles.legendItem}>
                    <View style={[styles.legendDot, { backgroundColor: colors.neutral.gray[400] }]} />
                    <Text style={styles.legendText}>Autre</Text>
                  </View>
                )}
              </View>
            </View>
          )}

          {/* Barre de progression vers l'objectif */}
          {weeklyData?.weekProgress && weeklyData.weekProgress.targetDuration > 0 && (
            <View style={styles.progressBarContainer}>
              <View style={styles.progressBarBackground}>
                <View
                  style={[
                    styles.progressBarFill,
                    { width: `${Math.min(weeklyData.weekProgress.percentage, 100)}%` },
                  ]}
                />
              </View>
              <Text style={styles.progressBarText}>
                {weeklyData.weekProgress.percentage}% de l'objectif hebdomadaire
              </Text>
            </View>
          )}

          {/* Indicateur cliquable */}
          <View style={styles.progressCardFooter}>
            <Text style={styles.progressCardFooterText}>Voir les détails</Text>
            <Icon name="chevron-forward" size={16} color={colors.primary[500]} />
          </View>
        </TouchableOpacity>
      </View>

      {/* AI Coach Insights */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Conseils du Coach IA</Text>
        <TouchableOpacity
          style={styles.insightCard}
          onPress={() => navigation.navigate('Main', { screen: 'CoachChat' })}
          activeOpacity={0.7}
        >
          <View style={styles.insightHeader}>
            <Icon name="bulb" size={24} color={colors.primary[500]} />
            <Text style={styles.insightTitle}>Commencez votre parcours</Text>
          </View>
          <Text style={styles.insightText}>
            Bienvenue sur EdgeCoach ! Créez votre premier plan d'entraînement
            ou discutez avec votre Coach IA pour des conseils personnalisés.
          </Text>
          <View style={styles.insightAction}>
            <Text style={styles.insightActionText}>Parler au Coach</Text>
            <Icon name="arrow-forward" size={16} color={colors.primary[500]} />
          </View>
        </TouchableOpacity>
      </View>

      {/* Upcoming Workouts */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Prochaines séances</Text>
        {loading ? (
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="small" color={colors.primary[500]} />
          </View>
        ) : weeklyData?.upcomingSessions && weeklyData.upcomingSessions.length > 0 ? (
          <View style={styles.upcomingList}>
            {weeklyData.upcomingSessions.map((session) => (
              <TouchableOpacity key={session.id} style={styles.upcomingCard}>
                <View style={styles.upcomingIconContainer}>
                  <Icon
                    name={
                      session.sport.toLowerCase().includes('cycl') ? 'bicycle' :
                      session.sport.toLowerCase().includes('course') || session.sport.toLowerCase().includes('run') ? 'walk' :
                      session.sport.toLowerCase().includes('nat') || session.sport.toLowerCase().includes('swim') ? 'water' :
                      'fitness'
                    }
                    size={20}
                    color={colors.primary[500]}
                  />
                </View>
                <View style={styles.upcomingContent}>
                  <Text style={styles.upcomingName} numberOfLines={1}>{session.name}</Text>
                  <Text style={styles.upcomingMeta}>
                    {new Date(session.date).toLocaleDateString('fr-FR', { weekday: 'short', day: 'numeric', month: 'short' })}
                    {session.duration ? ` • ${session.duration}min` : ''}
                  </Text>
                </View>
                <Icon name="chevron-forward" size={20} color={colors.neutral.gray[400]} />
              </TouchableOpacity>
            ))}
          </View>
        ) : (
          <View style={styles.emptyState}>
            <Icon name="calendar-outline" size={48} color={colors.neutral.gray[300]} />
            <Text style={styles.emptyStateText}>
              Aucune séance planifiée
            </Text>
            <TouchableOpacity style={styles.emptyStateButton}>
              <Text style={styles.emptyStateButtonText}>Créer un plan</Text>
            </TouchableOpacity>
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
  welcomeSection: {
    marginBottom: spacing.lg,
  },
  greeting: {
    ...typography.styles.h2,
    color: colors.secondary[800],
  },
  welcomeSubtitle: {
    ...typography.styles.body,
    color: colors.neutral.gray[500],
    marginTop: spacing.xs,
  },
  quickActions: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: spacing.lg,
  },
  quickActionCard: {
    flex: 1,
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.md,
    marginHorizontal: spacing.xs,
    alignItems: 'center',
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  iconContainer: {
    width: 56,
    height: 56,
    borderRadius: spacing.borderRadius.full,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: spacing.sm,
  },
  quickActionTitle: {
    ...typography.styles.label,
    color: colors.secondary[800],
  },
  quickActionSubtitle: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  section: {
    marginBottom: spacing.lg,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.md,
  },
  sectionTitle: {
    ...typography.styles.h4,
    color: colors.secondary[800],
  },
  seeMoreText: {
    ...typography.styles.label,
    color: colors.primary[500],
  },
  progressCard: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.lg,
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  progressRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  progressItem: {
    alignItems: 'center',
    flex: 1,
  },
  progressIconContainer: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: colors.primary[50],
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: spacing.xs,
  },
  progressValue: {
    ...typography.styles.h3,
    color: colors.primary[500],
  },
  progressLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    marginTop: spacing.xs,
  },
  progressDivider: {
    width: 1,
    backgroundColor: colors.neutral.gray[200],
  },
  progressRowSecondary: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: spacing.xl,
    marginTop: spacing.md,
    paddingTop: spacing.md,
    borderTopWidth: 1,
    borderTopColor: colors.neutral.gray[100],
  },
  progressItemSecondary: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  progressValueSecondary: {
    ...typography.styles.bodySmall,
    color: colors.neutral.gray[600],
  },
  sportBreakdown: {
    marginTop: spacing.md,
    paddingTop: spacing.md,
    borderTopWidth: 1,
    borderTopColor: colors.neutral.gray[100],
  },
  sportBreakdownTitle: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    marginBottom: spacing.sm,
  },
  sportBreakdownBar: {
    flexDirection: 'row',
    height: 8,
    borderRadius: 4,
    overflow: 'hidden',
    gap: 2,
  },
  sportBreakdownSegment: {
    borderRadius: 4,
  },
  sportBreakdownLegend: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.md,
    marginTop: spacing.sm,
  },
  legendItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  legendDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  legendText: {
    ...typography.styles.caption,
    color: colors.neutral.gray[600],
  },
  progressCardFooter: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: spacing.md,
    paddingTop: spacing.md,
    borderTopWidth: 1,
    borderTopColor: colors.neutral.gray[100],
    gap: spacing.xs,
  },
  progressCardFooterText: {
    ...typography.styles.label,
    color: colors.primary[500],
  },
  insightCard: {
    backgroundColor: colors.primary[50],
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.lg,
    borderLeftWidth: 4,
    borderLeftColor: colors.primary[500],
  },
  insightHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing.sm,
  },
  insightTitle: {
    ...typography.styles.label,
    color: colors.secondary[800],
    marginLeft: spacing.sm,
  },
  insightText: {
    ...typography.styles.bodySmall,
    color: colors.secondary[600],
    lineHeight: 22,
  },
  insightAction: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: spacing.md,
  },
  insightActionText: {
    ...typography.styles.label,
    color: colors.primary[500],
    marginRight: spacing.xs,
  },
  emptyState: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.xl,
    alignItems: 'center',
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  emptyStateText: {
    ...typography.styles.body,
    color: colors.neutral.gray[500],
    marginTop: spacing.md,
    marginBottom: spacing.md,
  },
  emptyStateButton: {
    backgroundColor: colors.primary[500],
    paddingVertical: spacing.sm,
    paddingHorizontal: spacing.lg,
    borderRadius: spacing.borderRadius.md,
  },
  emptyStateButtonText: {
    ...typography.styles.buttonSmall,
    color: colors.neutral.white,
  },
  // Progress bar styles
  progressBarContainer: {
    marginTop: spacing.md,
  },
  progressBarBackground: {
    height: 8,
    backgroundColor: colors.neutral.gray[200],
    borderRadius: 4,
    overflow: 'hidden',
  },
  progressBarFill: {
    height: '100%',
    backgroundColor: colors.primary[500],
    borderRadius: 4,
  },
  progressBarText: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    marginTop: spacing.xs,
    textAlign: 'center',
  },
  // Loading state
  loadingContainer: {
    padding: spacing.xl,
    alignItems: 'center',
  },
  // Upcoming sessions
  upcomingList: {
    gap: spacing.sm,
  },
  upcomingCard: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 1,
    marginBottom: spacing.sm,
  },
  upcomingIconContainer: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.primary[50],
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: spacing.md,
  },
  upcomingContent: {
    flex: 1,
  },
  upcomingName: {
    ...typography.styles.label,
    color: colors.secondary[800],
  },
  upcomingMeta: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    marginTop: 2,
  },
  // Other category card
  otherCard: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.md,
    marginHorizontal: spacing.xs,
    marginBottom: spacing.lg,
    flexDirection: 'row',
    alignItems: 'center',
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  otherIconContainer: {
    width: 44,
    height: 44,
    borderRadius: 22,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: spacing.md,
  },
  otherContent: {
    flex: 1,
  },
  otherTitle: {
    ...typography.styles.label,
    color: colors.secondary[800],
  },
  otherSubtitle: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
});

export default DashboardScreen;
