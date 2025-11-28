/**
 * Écran Statistiques Avancées
 * Métriques niveau Wahoo/Garmin: CTL/ATL/TSB, Radar, PDC, Sessions détaillées
 */

import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  ActivityIndicator,
  Dimensions,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { colors, spacing, typography } from '../theme';
import { useAuth } from '../contexts/AuthContext';
import {
  statsService,
  statsAdvancedService,
  StatsData,
  StatsPeriod,
  AdvancedStatsData,
  TrainingLoadSimple,
} from '../services';

const { width: SCREEN_WIDTH } = Dimensions.get('window');

// Périodes disponibles
const PERIODS: { value: StatsPeriod; label: string }[] = [
  { value: 'week', label: 'Semaine' },
  { value: 'month', label: 'Mois' },
  { value: 'year', label: 'Année' },
];

// Convertir période en nombre de jours
const periodToDays = (period: StatsPeriod): number => {
  switch (period) {
    case 'week':
      return 7;
    case 'month':
      return 30;
    case 'year':
      return 365;
    default:
      return 7;
  }
};

const StatsScreen: React.FC = () => {
  const { user } = useAuth();
  const [selectedPeriod, setSelectedPeriod] = useState<StatsPeriod>('week');
  const [statsData, setStatsData] = useState<StatsData | null>(null);
  const [advancedData, setAdvancedData] = useState<AdvancedStatsData | null>(null);
  const [trainingLoad, setTrainingLoad] = useState<TrainingLoadSimple | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [selectedEvolutionIndex, setSelectedEvolutionIndex] = useState<number | null>(null);

  // Charger toutes les statistiques
  const loadStats = useCallback(async () => {
    if (!user?.id) {
      console.log('[StatsScreen] No user.id, skipping load');
      return;
    }

    const days = periodToDays(selectedPeriod);
    console.log(`[StatsScreen] ========== LOADING STATS ==========`);
    console.log(`[StatsScreen] user.id=${user.id}`);
    console.log(`[StatsScreen] selectedPeriod=${selectedPeriod}, days=${days}`);

    try {
      // Charger en parallèle: stats basiques + training load + advanced
      const [basicResult, loadResult, advancedResult] = await Promise.all([
        statsService.getStats(user.id, selectedPeriod),
        statsAdvancedService.getTrainingLoad(user.id, days),
        statsAdvancedService.getAdvancedStats(user.id, days, 'all'),
      ]);

      console.log(`[StatsScreen] Basic stats received for period=${selectedPeriod}:`);
      console.log(`[StatsScreen]   - sessions: ${basicResult.data?.summary?.sessionsCount}`);
      console.log(`[StatsScreen]   - duration: ${basicResult.data?.summary?.totalDuration}s`);
      console.log(`[StatsScreen]   - distance: ${basicResult.data?.summary?.totalDistance}m`);
      console.log(`[StatsScreen]   - dates: ${basicResult.data?.startDate} to ${basicResult.data?.endDate}`);

      if (basicResult.success && basicResult.data) {
        setStatsData(basicResult.data);
      } else {
        console.log(`[StatsScreen] Basic stats failed, using empty stats`);
        setStatsData(statsService.getEmptyStats(selectedPeriod));
      }

      if (loadResult.success && loadResult.data) {
        setTrainingLoad(loadResult.data);
      }

      if (advancedResult.success && advancedResult.data) {
        setAdvancedData(advancedResult.data);
      }

      // Reset sélection graphique
      setSelectedEvolutionIndex(null);
    } catch (error) {
      console.error('[StatsScreen] Erreur chargement stats:', error);
      setStatsData(statsService.getEmptyStats(selectedPeriod));
    } finally {
      setLoading(false);
    }
  }, [user?.id, selectedPeriod]);

  useEffect(() => {
    setLoading(true);
    loadStats();
  }, [loadStats]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await loadStats();
    setRefreshing(false);
  }, [loadStats]);

  const handlePeriodChange = (period: StatsPeriod) => {
    console.log(`[StatsScreen] Period change requested: ${selectedPeriod} -> ${period}`);
    if (period !== selectedPeriod) {
      console.log(`[StatsScreen] Setting new period: ${period}`);
      setLoading(true);
      setSelectedPeriod(period);
    }
  };

  // Affichage pendant le chargement initial
  if (loading && !statsData) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color={colors.primary[500]} />
        <Text style={styles.loadingText}>Chargement des statistiques...</Text>
      </View>
    );
  }

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.content}
      refreshControl={
        <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
      }
    >
      {/* Period Selector */}
      <View style={styles.periodSelector}>
        {PERIODS.map((period) => (
          <TouchableOpacity
            key={period.value}
            style={[
              styles.periodButton,
              selectedPeriod === period.value && styles.periodButtonActive,
            ]}
            onPress={() => handlePeriodChange(period.value)}
            disabled={loading}
          >
            <Text
              style={[
                styles.periodButtonText,
                selectedPeriod === period.value && styles.periodButtonTextActive,
              ]}
            >
              {period.label}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      {/* Training Load Card (CTL/ATL/TSB) */}
      {trainingLoad && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Charge d'entraînement</Text>
          <View style={styles.trainingLoadCard}>
            {/* Status Badge */}
            <View style={[
              styles.statusBadge,
              { backgroundColor: statsAdvancedService.getTsbStatusColor(trainingLoad.status) + '20' }
            ]}>
              <View style={[
                styles.statusDot,
                { backgroundColor: statsAdvancedService.getTsbStatusColor(trainingLoad.status) }
              ]} />
              <Text style={[
                styles.statusText,
                { color: statsAdvancedService.getTsbStatusColor(trainingLoad.status) }
              ]}>
                {trainingLoad.statusLabel}
              </Text>
            </View>

            {/* CTL / ATL / TSB */}
            <View style={styles.loadMetricsRow}>
              <View style={styles.loadMetric}>
                <Text style={styles.loadMetricValue}>{trainingLoad.ctl?.toFixed(0) ?? '--'}</Text>
                <Text style={styles.loadMetricLabel}>Forme (CTL)</Text>
                <Text style={styles.loadMetricSub}>Fitness</Text>
              </View>
              <View style={styles.loadMetricDivider} />
              <View style={styles.loadMetric}>
                <Text style={styles.loadMetricValue}>{trainingLoad.atl?.toFixed(0) ?? '--'}</Text>
                <Text style={styles.loadMetricLabel}>Fatigue (ATL)</Text>
                <Text style={styles.loadMetricSub}>7 jours</Text>
              </View>
              <View style={styles.loadMetricDivider} />
              <View style={styles.loadMetric}>
                <Text style={[
                  styles.loadMetricValue,
                  { color: statsAdvancedService.getTsbStatusColor(trainingLoad.status) }
                ]}>
                  {trainingLoad.tsb?.toFixed(0) ?? '--'}
                </Text>
                <Text style={styles.loadMetricLabel}>Fraîcheur (TSB)</Text>
                <Text style={styles.loadMetricSub}>Form</Text>
              </View>
            </View>

            {/* TSS résumé */}
            <View style={styles.tssRow}>
              <View style={styles.tssItem}>
                <Icon name="calendar-outline" size={16} color={colors.neutral.gray[400]} />
                <Text style={styles.tssLabel}>7 jours:</Text>
                <Text style={styles.tssValue}>{trainingLoad.last7dTss?.toFixed(0) ?? '--'} TSS</Text>
              </View>
              <View style={styles.tssItem}>
                <Icon name="trending-up-outline" size={16} color={colors.neutral.gray[400]} />
                <Text style={styles.tssLabel}>42 jours:</Text>
                <Text style={styles.tssValue}>{trainingLoad.last42dTss?.toFixed(0) ?? '--'} TSS</Text>
              </View>
            </View>
          </View>
        </View>
      )}

      {/* Radar de l'athlète */}
      {advancedData?.radar && advancedData.radar.overall > 0 && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Profil athlète</Text>
          <View style={styles.radarCard}>
            {/* Score global */}
            <View style={styles.radarOverall}>
              <Text style={styles.radarOverallValue}>{advancedData.radar.overall}</Text>
              <Text style={styles.radarOverallLabel}>Score global</Text>
            </View>

            {/* Axes du radar */}
            <View style={styles.radarAxes}>
              <RadarAxis
                label="Endurance aérobie"
                value={advancedData.radar.aerobicEndurance}
                icon="heart"
              />
              <RadarAxis
                label="Seuil"
                value={advancedData.radar.thresholdDurability}
                icon="speedometer"
              />
              <RadarAxis
                label="VO2 / Haute intensité"
                value={advancedData.radar.vo2Hi}
                icon="flash"
              />
              <RadarAxis
                label="Technique / Économie"
                value={advancedData.radar.techniqueEconomy}
                icon="body"
              />
              <RadarAxis
                label="Constance"
                value={advancedData.radar.consistencyLoad}
                icon="repeat"
              />
            </View>
          </View>
        </View>
      )}

      {/* Summary Cards */}
      <View style={styles.summaryCards}>
        <View style={styles.summaryCard}>
          <Icon name="time-outline" size={24} color={colors.primary[500]} />
          <Text style={styles.summaryValue}>
            {statsService.formatDuration(statsData?.summary.totalDuration || 0)}
          </Text>
          <Text style={styles.summaryLabel}>Temps total</Text>
        </View>
        <View style={styles.summaryCard}>
          <Icon name="flame-outline" size={24} color={colors.status.error} />
          <Text style={styles.summaryValue}>
            {statsService.formatCalories(statsData?.summary.totalCalories || 0)}
          </Text>
          <Text style={styles.summaryLabel}>Calories</Text>
        </View>
        <View style={styles.summaryCard}>
          <Icon name="navigate-outline" size={24} color={colors.sports.running} />
          <Text style={styles.summaryValue}>
            {statsService.formatDistance(statsData?.summary.totalDistance || 0)}
          </Text>
          <Text style={styles.summaryLabel}>Distance</Text>
        </View>
      </View>

      {/* Sport Breakdown */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Répartition par sport</Text>
        <View style={styles.sportBreakdown}>
          <SportItem
            icon="bicycle"
            color={colors.sports.cycling}
            name="Vélo"
            duration={statsData?.byDiscipline.cyclisme.duration || 0}
            distance={statsData?.byDiscipline.cyclisme.distance || 0}
            percentage={statsData?.byDiscipline.cyclisme.percentage || 0}
          />
          <SportItem
            icon="walk"
            color={colors.sports.running}
            name="Course"
            duration={statsData?.byDiscipline.course.duration || 0}
            distance={statsData?.byDiscipline.course.distance || 0}
            percentage={statsData?.byDiscipline.course.percentage || 0}
          />
          <SportItem
            icon="water"
            color={colors.sports.swimming}
            name="Natation"
            duration={statsData?.byDiscipline.natation.duration || 0}
            distance={statsData?.byDiscipline.natation.distance || 0}
            percentage={statsData?.byDiscipline.natation.percentage || 0}
            isSwimming
          />
        </View>
      </View>

      {/* Graphique d'évolution interactif */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Évolution</Text>
        {statsData?.evolution && statsData.evolution.length > 0 ? (
          <View style={styles.evolutionCard}>
            {/* Info sélectionnée */}
            {selectedEvolutionIndex !== null && statsData.evolution[selectedEvolutionIndex] && (
              <View style={styles.evolutionTooltip}>
                <Text style={styles.evolutionTooltipDate}>
                  {new Date(statsData.evolution[selectedEvolutionIndex].date).toLocaleDateString('fr-FR', {
                    weekday: 'long',
                    day: 'numeric',
                    month: 'long',
                  })}
                </Text>
                <View style={styles.evolutionTooltipRow}>
                  <View style={styles.evolutionTooltipItem}>
                    <Icon name="time-outline" size={14} color={colors.primary[500]} />
                    <Text style={styles.evolutionTooltipValue}>
                      {statsService.formatDuration(statsData.evolution[selectedEvolutionIndex].duration)}
                    </Text>
                  </View>
                  <View style={styles.evolutionTooltipItem}>
                    <Icon name="navigate-outline" size={14} color={colors.sports.running} />
                    <Text style={styles.evolutionTooltipValue}>
                      {statsService.formatDistance(statsData.evolution[selectedEvolutionIndex].distance)}
                    </Text>
                  </View>
                </View>
              </View>
            )}

            {/* Barres du graphique */}
            <View style={styles.evolutionBars}>
              {statsData.evolution.map((point, index) => {
                const maxDuration = Math.max(...statsData.evolution.map(p => p.duration), 1);
                const heightPercent = Math.min((point.duration / maxDuration) * 100, 100);
                const isSelected = selectedEvolutionIndex === index;

                return (
                  <TouchableOpacity
                    key={point.date}
                    style={styles.evolutionBarWrapper}
                    onPress={() => setSelectedEvolutionIndex(isSelected ? null : index)}
                    activeOpacity={0.7}
                  >
                    <View style={styles.evolutionBarContainer}>
                      <View
                        style={[
                          styles.evolutionBar,
                          {
                            height: `${heightPercent}%`,
                            backgroundColor: isSelected ? colors.primary[600] : colors.primary[400],
                            opacity: isSelected ? 1 : 0.7,
                          },
                        ]}
                      />
                    </View>
                    <Text style={[
                      styles.evolutionBarLabel,
                      isSelected && styles.evolutionBarLabelSelected,
                    ]}>
                      {selectedPeriod === 'year'
                        ? new Date(point.date).toLocaleDateString('fr-FR', { month: 'short' }).slice(0, 3)
                        : new Date(point.date).toLocaleDateString('fr-FR', { weekday: 'short' }).slice(0, 2)
                      }
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>

            {/* Légende */}
            <View style={styles.evolutionLegend}>
              <Text style={styles.evolutionLegendText}>
                Touchez une barre pour voir les détails
              </Text>
            </View>
          </View>
        ) : (
          <View style={styles.emptyChart}>
            <Icon name="bar-chart-outline" size={48} color={colors.neutral.gray[300]} />
            <Text style={styles.emptyChartText}>
              Pas encore de données pour cette période
            </Text>
          </View>
        )}
      </View>

      {/* Dernières séances avec métriques */}
      {advancedData?.sessions && advancedData.sessions.length > 0 && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Dernières séances</Text>
          <View style={styles.sessionsCard}>
            {advancedData.sessions.slice(0, 5).map((session, index) => (
              <SessionRow key={session.sessionId || index} session={session} />
            ))}
          </View>
        </View>
      )}

      {/* Alertes / Décisions */}
      {advancedData?.decisions && advancedData.decisions.length > 0 && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Alertes</Text>
          <View style={styles.alertsCard}>
            {advancedData.decisions.slice(0, 3).map((decision, index) => (
              <AlertRow key={decision.ruleId || index} decision={decision} />
            ))}
          </View>
        </View>
      )}

      {/* Performance Metrics */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Métriques de performance</Text>
        <View style={styles.metricsGrid}>
          <View style={styles.metricCard}>
            <Text style={styles.metricValue}>
              {advancedData?.profile?.cyclingFtp ?? statsData?.performanceMetrics.ftp ?? '--'}
            </Text>
            <Text style={styles.metricLabel}>FTP (W)</Text>
          </View>
          <View style={styles.metricCard}>
            <Text style={styles.metricValue}>
              {advancedData?.profile?.hrMax ?? statsData?.performanceMetrics.maxHr ?? '--'}
            </Text>
            <Text style={styles.metricLabel}>FC Max</Text>
          </View>
          <View style={styles.metricCard}>
            <Text style={styles.metricValue}>
              {advancedData?.profile?.runningVma ?? statsData?.performanceMetrics.vma ?? '--'}
            </Text>
            <Text style={styles.metricLabel}>VMA (km/h)</Text>
          </View>
          <View style={styles.metricCard}>
            <Text style={styles.metricValue}>
              {advancedData?.profile?.swimmingCss
                ? `${Math.floor(advancedData.profile.swimmingCss / 60)}:${String(Math.round(advancedData.profile.swimmingCss % 60)).padStart(2, '0')}`
                : statsData?.performanceMetrics.css ?? '--'}
            </Text>
            <Text style={styles.metricLabel}>CSS (/100m)</Text>
          </View>
        </View>
      </View>

      {/* Sessions count */}
      <View style={styles.sessionsInfo}>
        <Text style={styles.sessionsInfoText}>
          {statsData?.summary.sessionsCount || 0} séance{(statsData?.summary.sessionsCount || 0) > 1 ? 's' : ''} sur cette période
        </Text>
        {advancedData?.meta && (
          <Text style={styles.sessionsInfoSubtext}>
            Analyse sur {advancedData.meta.daysAnalyzed} jours
          </Text>
        )}
      </View>
    </ScrollView>
  );
};

// ============ COMPOSANTS HELPER ============

interface RadarAxisProps {
  label: string;
  value: number;
  icon: string;
}

const RadarAxis: React.FC<RadarAxisProps> = ({ label, value, icon }) => (
  <View style={styles.radarAxisItem}>
    <View style={styles.radarAxisHeader}>
      <Icon name={icon} size={16} color={colors.primary[500]} />
      <Text style={styles.radarAxisLabel}>{label}</Text>
    </View>
    <View style={styles.radarAxisBar}>
      <View style={[styles.radarAxisFill, { width: `${value}%` }]} />
    </View>
    <Text style={styles.radarAxisValue}>{value}</Text>
  </View>
);

interface SportItemProps {
  icon: string;
  color: string;
  name: string;
  duration: number;
  distance: number;
  percentage: number;
  isSwimming?: boolean;
}

const SportItem: React.FC<SportItemProps> = ({
  icon,
  color,
  name,
  duration,
  distance,
  percentage,
  isSwimming,
}) => (
  <View style={styles.sportItem}>
    <View style={[styles.sportIcon, { backgroundColor: color + '20' }]}>
      <Icon name={icon} size={24} color={color} />
    </View>
    <View style={styles.sportInfo}>
      <Text style={styles.sportName}>{name}</Text>
      <Text style={styles.sportStats}>
        {statsService.formatDuration(duration)} · {statsService.formatDistance(distance, isSwimming ? 'natation' : undefined)}
      </Text>
    </View>
    <Text style={styles.sportPercent}>{percentage}%</Text>
  </View>
);

interface SessionRowProps {
  session: AdvancedStatsData['sessions'][0];
}

const SessionRow: React.FC<SessionRowProps> = ({ session }) => {
  const sportIcons: Record<string, string> = {
    running: 'walk',
    cycling: 'bicycle',
    swimming: 'water',
  };
  const sportColors: Record<string, string> = {
    running: colors.sports.running,
    cycling: colors.sports.cycling,
    swimming: colors.sports.swimming,
  };

  return (
    <View style={styles.sessionRow}>
      <View style={[
        styles.sessionIcon,
        { backgroundColor: (sportColors[session.sport] || colors.primary[500]) + '20' }
      ]}>
        <Icon
          name={sportIcons[session.sport] || 'fitness'}
          size={18}
          color={sportColors[session.sport] || colors.primary[500]}
        />
      </View>
      <View style={styles.sessionInfo}>
        <Text style={styles.sessionDate}>
          {new Date(session.date).toLocaleDateString('fr-FR', {
            weekday: 'short',
            day: 'numeric',
            month: 'short',
          })}
        </Text>
        <Text style={styles.sessionMetrics}>
          {session.durationMin ? `${Math.round(session.durationMin)}min` : ''}
          {session.distanceKm ? ` · ${session.distanceKm.toFixed(1)}km` : ''}
          {session.tss ? ` · TSS ${session.tss.toFixed(0)}` : ''}
        </Text>
      </View>
      {session.np && (
        <View style={styles.sessionNp}>
          <Text style={styles.sessionNpValue}>{session.np.toFixed(0)}</Text>
          <Text style={styles.sessionNpLabel}>NP</Text>
        </View>
      )}
    </View>
  );
};

interface AlertRowProps {
  decision: AdvancedStatsData['decisions'][0];
}

const AlertRow: React.FC<AlertRowProps> = ({ decision }) => {
  const severityColors: Record<string, string> = {
    info: colors.primary[500],
    warning: colors.status.warning,
    critical: colors.status.error,
  };
  const severityIcons: Record<string, string> = {
    info: 'information-circle',
    warning: 'warning',
    critical: 'alert-circle',
  };

  return (
    <View style={styles.alertRow}>
      <Icon
        name={severityIcons[decision.severity] || 'information-circle'}
        size={20}
        color={severityColors[decision.severity] || colors.primary[500]}
      />
      <Text style={styles.alertText}>{decision.label}</Text>
    </View>
  );
};

// ============ STYLES ============

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.light.background,
  },
  content: {
    padding: spacing.container.horizontal,
    paddingBottom: spacing.xl,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.light.background,
  },
  loadingText: {
    ...typography.styles.body,
    color: colors.neutral.gray[500],
    marginTop: spacing.md,
  },
  periodSelector: {
    flexDirection: 'row',
    backgroundColor: colors.neutral.gray[100],
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.xs,
    marginBottom: spacing.lg,
  },
  periodButton: {
    flex: 1,
    paddingVertical: spacing.sm,
    alignItems: 'center',
    borderRadius: spacing.borderRadius.md,
  },
  periodButtonActive: {
    backgroundColor: colors.neutral.white,
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  periodButtonText: {
    ...typography.styles.label,
    color: colors.neutral.gray[500],
  },
  periodButtonTextActive: {
    color: colors.secondary[800],
  },
  section: {
    marginBottom: spacing.lg,
  },
  sectionTitle: {
    ...typography.styles.h4,
    color: colors.secondary[800],
    marginBottom: spacing.md,
  },

  // Training Load Card
  trainingLoadCard: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.lg,
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  statusBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    borderRadius: spacing.borderRadius.full,
    marginBottom: spacing.md,
  },
  statusDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: spacing.xs,
  },
  statusText: {
    ...typography.styles.caption,
    fontWeight: '600',
  },
  loadMetricsRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'center',
    paddingVertical: spacing.md,
  },
  loadMetric: {
    flex: 1,
    alignItems: 'center',
  },
  loadMetricDivider: {
    width: 1,
    height: 40,
    backgroundColor: colors.neutral.gray[200],
  },
  loadMetricValue: {
    ...typography.styles.h2,
    color: colors.secondary[800],
  },
  loadMetricLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[600],
    marginTop: spacing.xs,
  },
  loadMetricSub: {
    ...typography.styles.caption,
    color: colors.neutral.gray[400],
    fontSize: 10,
  },
  tssRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    borderTopWidth: 1,
    borderTopColor: colors.neutral.gray[100],
    paddingTop: spacing.md,
    marginTop: spacing.sm,
  },
  tssItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  tssLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  tssValue: {
    ...typography.styles.label,
    color: colors.secondary[800],
  },

  // Radar Card
  radarCard: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.lg,
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  radarOverall: {
    alignItems: 'center',
    marginBottom: spacing.lg,
  },
  radarOverallValue: {
    ...typography.styles.h1,
    color: colors.primary[500],
  },
  radarOverallLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  radarAxes: {
    gap: spacing.sm,
  },
  radarAxisItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  radarAxisHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    width: 140,
    gap: spacing.xs,
  },
  radarAxisLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[600],
    flex: 1,
  },
  radarAxisBar: {
    flex: 1,
    height: 6,
    backgroundColor: colors.neutral.gray[100],
    borderRadius: 3,
    overflow: 'hidden',
  },
  radarAxisFill: {
    height: '100%',
    backgroundColor: colors.primary[500],
    borderRadius: 3,
  },
  radarAxisValue: {
    ...typography.styles.label,
    color: colors.secondary[800],
    width: 30,
    textAlign: 'right',
  },

  // Summary Cards
  summaryCards: {
    flexDirection: 'row',
    gap: spacing.sm,
    marginBottom: spacing.lg,
  },
  summaryCard: {
    flex: 1,
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.md,
    alignItems: 'center',
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  summaryValue: {
    ...typography.styles.h3,
    color: colors.secondary[800],
    marginTop: spacing.sm,
  },
  summaryLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    marginTop: spacing.xs,
  },

  // Sport Breakdown
  sportBreakdown: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.md,
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  sportItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing.sm,
  },
  sportIcon: {
    width: 48,
    height: 48,
    borderRadius: spacing.borderRadius.md,
    justifyContent: 'center',
    alignItems: 'center',
  },
  sportInfo: {
    flex: 1,
    marginLeft: spacing.md,
  },
  sportName: {
    ...typography.styles.label,
    color: colors.secondary[800],
  },
  sportStats: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    marginTop: spacing.xs,
  },
  sportPercent: {
    ...typography.styles.label,
    color: colors.neutral.gray[400],
  },

  // Sessions Card
  sessionsCard: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.md,
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  sessionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: colors.neutral.gray[100],
  },
  sessionIcon: {
    width: 36,
    height: 36,
    borderRadius: spacing.borderRadius.md,
    justifyContent: 'center',
    alignItems: 'center',
  },
  sessionInfo: {
    flex: 1,
    marginLeft: spacing.sm,
  },
  sessionDate: {
    ...typography.styles.label,
    color: colors.secondary[800],
  },
  sessionMetrics: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  sessionNp: {
    alignItems: 'center',
  },
  sessionNpValue: {
    ...typography.styles.label,
    color: colors.primary[500],
  },
  sessionNpLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[400],
    fontSize: 10,
  },

  // Alerts Card
  alertsCard: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.md,
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  alertRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing.sm,
    gap: spacing.sm,
  },
  alertText: {
    ...typography.styles.body,
    color: colors.secondary[800],
    flex: 1,
  },

  // Metrics Grid
  metricsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.sm,
  },
  metricCard: {
    width: '48%',
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.md,
    alignItems: 'center',
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  metricValue: {
    ...typography.styles.h3,
    color: colors.primary[500],
  },
  metricLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    marginTop: spacing.xs,
  },

  // Sessions Info
  sessionsInfo: {
    alignItems: 'center',
    paddingVertical: spacing.md,
  },
  sessionsInfoText: {
    ...typography.styles.bodySmall,
    color: colors.neutral.gray[500],
  },
  sessionsInfoSubtext: {
    ...typography.styles.caption,
    color: colors.neutral.gray[400],
    marginTop: spacing.xs,
  },

  // Evolution Chart
  evolutionCard: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.lg,
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  evolutionTooltip: {
    backgroundColor: colors.neutral.gray[50],
    borderRadius: spacing.borderRadius.md,
    padding: spacing.sm,
    marginBottom: spacing.md,
    borderLeftWidth: 3,
    borderLeftColor: colors.primary[500],
  },
  evolutionTooltipDate: {
    ...typography.styles.label,
    color: colors.secondary[800],
    textTransform: 'capitalize',
    marginBottom: spacing.xs,
  },
  evolutionTooltipRow: {
    flexDirection: 'row',
    gap: spacing.lg,
  },
  evolutionTooltipItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  evolutionTooltipValue: {
    ...typography.styles.body,
    color: colors.secondary[800],
    fontWeight: '600',
  },
  evolutionBars: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    height: 150,
    gap: 4,
  },
  evolutionBarWrapper: {
    flex: 1,
    alignItems: 'center',
  },
  evolutionBarContainer: {
    width: '100%',
    height: 130,
    justifyContent: 'flex-end',
    alignItems: 'center',
  },
  evolutionBar: {
    width: '80%',
    maxWidth: 32,
    borderRadius: 4,
    minHeight: 4,
  },
  evolutionBarLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[400],
    marginTop: spacing.xs,
    fontSize: 10,
    textTransform: 'capitalize',
  },
  evolutionBarLabelSelected: {
    color: colors.primary[600],
    fontWeight: '600',
  },
  evolutionLegend: {
    alignItems: 'center',
    marginTop: spacing.md,
    paddingTop: spacing.sm,
    borderTopWidth: 1,
    borderTopColor: colors.neutral.gray[100],
  },
  evolutionLegendText: {
    ...typography.styles.caption,
    color: colors.neutral.gray[400],
  },
  emptyChart: {
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
  emptyChartText: {
    ...typography.styles.body,
    color: colors.neutral.gray[500],
    textAlign: 'center',
    marginTop: spacing.md,
  },
});

export default StatsScreen;
