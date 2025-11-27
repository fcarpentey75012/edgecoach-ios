/**
 * Composant de résumé hebdomadaire
 * Affiche les statistiques de la semaine : volume, charge, répartition
 */

import React, { useMemo } from 'react';
import { View, Text, StyleSheet, Dimensions } from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { colors, spacing, typography } from '../../theme';
import { Activity } from '../../services/activitiesService';
import { PlannedSession } from '../../services/plansService';
import { ZonesChartCompact } from '../session/ZonesChart';

const SCREEN_WIDTH = Dimensions.get('window').width;

interface WeekSummaryProps {
  completedSessions: Activity[];
  plannedSessions: PlannedSession[];
  weekStart: Date;
  weekEnd: Date;
}

interface SportSummary {
  discipline: string;
  icon: string;
  color: string;
  sessions: number;
  totalDurationMinutes: number;
  totalDistanceKm: number;
}

// Parser la durée en minutes
const parseDurationToMinutes = (duration: string | null): number => {
  if (!duration) return 0;

  const minMatch = duration.match(/^(\d+)min$/);
  if (minMatch) return parseInt(minMatch[1], 10);

  const hourMinMatch = duration.match(/^(\d+):(\d+)$/);
  if (hourMinMatch) {
    return parseInt(hourMinMatch[1], 10) * 60 + parseInt(hourMinMatch[2], 10);
  }

  return 0;
};

// Parser la distance en km
const parseDistanceToKm = (distance: string | null): number => {
  if (!distance) return 0;

  const kmMatch = distance.match(/^([\d.]+)\s*km$/);
  if (kmMatch) return parseFloat(kmMatch[1]);

  const mMatch = distance.match(/^(\d+)\s*m$/);
  if (mMatch) return parseInt(mMatch[1], 10) / 1000;

  return 0;
};

// Formater la durée en heures et minutes
const formatDuration = (minutes: number): string => {
  const hours = Math.floor(minutes / 60);
  const mins = minutes % 60;
  if (hours === 0) return `${mins}min`;
  if (mins === 0) return `${hours}h`;
  return `${hours}h${mins.toString().padStart(2, '0')}`;
};

// Formater la distance
const formatDistance = (km: number): string => {
  if (km === 0) return '-';
  if (km < 1) return `${Math.round(km * 1000)}m`;
  return `${km.toFixed(1)}km`;
};

// Config des sports
const SPORT_CONFIG: Record<string, { icon: string; color: string; name: string }> = {
  cyclisme: { icon: 'bicycle', color: colors.sports.cycling, name: 'Vélo' },
  course: { icon: 'walk', color: colors.sports.running, name: 'Course' },
  natation: { icon: 'water', color: colors.sports.swimming, name: 'Natation' },
  autre: { icon: 'fitness', color: colors.neutral.gray[400], name: 'Autre' },
};

const WeekSummary: React.FC<WeekSummaryProps> = ({
  completedSessions,
  plannedSessions,
  weekStart,
  weekEnd,
}) => {
  // Calculer les statistiques par sport
  const sportSummaries = useMemo(() => {
    const summaries: Record<string, SportSummary> = {};

    completedSessions.forEach(session => {
      const discipline = session.discipline || 'autre';
      const config = SPORT_CONFIG[discipline] || SPORT_CONFIG.autre;

      if (!summaries[discipline]) {
        summaries[discipline] = {
          discipline,
          icon: config.icon,
          color: config.color,
          sessions: 0,
          totalDurationMinutes: 0,
          totalDistanceKm: 0,
        };
      }

      summaries[discipline].sessions += 1;
      summaries[discipline].totalDurationMinutes += parseDurationToMinutes(session.duration);
      summaries[discipline].totalDistanceKm += parseDistanceToKm(session.distance);
    });

    return Object.values(summaries);
  }, [completedSessions]);

  // Calculer les totaux
  const totals = useMemo(() => {
    let totalSessions = 0;
    let totalDurationMinutes = 0;
    let totalTSS = 0;
    let totalDistanceKm = 0;

    completedSessions.forEach(session => {
      totalSessions += 1;
      totalDurationMinutes += parseDurationToMinutes(session.duration);
      totalDistanceKm += parseDistanceToKm(session.distance);
      if (session.loadCoggan) totalTSS += session.loadCoggan;
    });

    return { totalSessions, totalDurationMinutes, totalTSS, totalDistanceKm };
  }, [completedSessions]);

  // Calculer le ratio prévu/réalisé
  const conformityRatio = useMemo(() => {
    if (plannedSessions.length === 0) return null;
    const completed = completedSessions.length;
    const planned = plannedSessions.length;
    return Math.round((completed / planned) * 100);
  }, [completedSessions, plannedSessions]);

  // Agréger les zones
  const aggregatedZones = useMemo(() => {
    const zonesMap: Record<number, { zone: number; time_seconds: number }> = {};

    completedSessions.forEach(session => {
      if (session.zones) {
        session.zones.forEach(zone => {
          if (!zonesMap[zone.zone]) {
            zonesMap[zone.zone] = { zone: zone.zone, time_seconds: 0 };
          }
          zonesMap[zone.zone].time_seconds += zone.time_seconds;
        });
      }
    });

    const totalTime = Object.values(zonesMap).reduce((sum, z) => sum + z.time_seconds, 0);
    return Object.values(zonesMap)
      .map(z => ({
        ...z,
        percentage: totalTime > 0 ? (z.time_seconds / totalTime) * 100 : 0,
      }))
      .sort((a, b) => a.zone - b.zone);
  }, [completedSessions]);

  // Formater la période
  const periodLabel = `${weekStart.toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' })} - ${weekEnd.toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' })}`;

  if (completedSessions.length === 0 && plannedSessions.length === 0) {
    return null;
  }

  return (
    <View style={styles.container}>
      {/* En-tête */}
      <View style={styles.header}>
        <View style={styles.headerLeft}>
          <Icon name="calendar-outline" size={18} color={colors.primary[600]} />
          <Text style={styles.headerTitle}>Résumé semaine</Text>
        </View>
        <Text style={styles.periodLabel}>{periodLabel}</Text>
      </View>

      {/* Statistiques principales */}
      <View style={styles.mainStats}>
        <View style={styles.mainStatItem}>
          <Text style={styles.mainStatValue}>{formatDuration(totals.totalDurationMinutes)}</Text>
          <Text style={styles.mainStatLabel}>Volume</Text>
        </View>
        <View style={styles.mainStatDivider} />
        <View style={styles.mainStatItem}>
          <Text style={styles.mainStatValue}>{totals.totalTSS > 0 ? totals.totalTSS : '-'}</Text>
          <Text style={styles.mainStatLabel}>TSS</Text>
        </View>
        <View style={styles.mainStatDivider} />
        <View style={styles.mainStatItem}>
          <Text style={styles.mainStatValue}>{totals.totalSessions}</Text>
          <Text style={styles.mainStatLabel}>Séances</Text>
        </View>
      </View>

      {/* Répartition par sport */}
      {sportSummaries.length > 0 && (
        <View style={styles.sportsSection}>
          {sportSummaries.map(sport => (
            <View key={sport.discipline} style={styles.sportRow}>
              <View style={styles.sportLeft}>
                <View style={[styles.sportIcon, { backgroundColor: sport.color + '20' }]}>
                  <Icon name={sport.icon} size={16} color={sport.color} />
                </View>
                <Text style={styles.sportSessions}>{sport.sessions}x</Text>
              </View>
              <View style={styles.sportRight}>
                <Text style={styles.sportDuration}>
                  {formatDuration(sport.totalDurationMinutes)}
                </Text>
                {sport.totalDistanceKm > 0 && (
                  <Text style={styles.sportDistance}>
                    ({formatDistance(sport.totalDistanceKm)})
                  </Text>
                )}
              </View>
            </View>
          ))}
        </View>
      )}

      {/* Zones agrégées */}
      {aggregatedZones.length > 0 && (
        <View style={styles.zonesSection}>
          <Text style={styles.sectionLabel}>Répartition zones</Text>
          <ZonesChartCompact zones={aggregatedZones} />
        </View>
      )}

      {/* Conformité au plan */}
      {conformityRatio !== null && (
        <View style={styles.conformitySection}>
          <Text style={styles.sectionLabel}>Conformité au plan</Text>
          <View style={styles.conformityBar}>
            <View style={styles.conformityTrack}>
              <View
                style={[
                  styles.conformityFill,
                  {
                    width: `${Math.min(conformityRatio, 100)}%`,
                    backgroundColor:
                      conformityRatio >= 80
                        ? colors.status.success
                        : conformityRatio >= 60
                        ? colors.status.warning
                        : colors.status.error,
                  },
                ]}
              />
            </View>
            <Text
              style={[
                styles.conformityValue,
                {
                  color:
                    conformityRatio >= 80
                      ? colors.status.success
                      : conformityRatio >= 60
                      ? colors.status.warning
                      : colors.status.error,
                },
              ]}
            >
              {conformityRatio}%
            </Text>
          </View>
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
    marginBottom: spacing.md,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.md,
  },
  headerLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  headerTitle: {
    ...typography.styles.label,
    color: colors.secondary[800],
    fontWeight: '600',
  },
  periodLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  mainStats: {
    flexDirection: 'row',
    backgroundColor: colors.primary[50],
    borderRadius: spacing.borderRadius.md,
    padding: spacing.md,
    marginBottom: spacing.md,
  },
  mainStatItem: {
    flex: 1,
    alignItems: 'center',
  },
  mainStatValue: {
    ...typography.styles.h3,
    color: colors.primary[700],
    fontWeight: '700',
  },
  mainStatLabel: {
    ...typography.styles.caption,
    color: colors.primary[600],
    marginTop: 2,
  },
  mainStatDivider: {
    width: 1,
    backgroundColor: colors.primary[200],
    marginVertical: spacing.xs,
  },
  sportsSection: {
    gap: spacing.xs,
    marginBottom: spacing.md,
  },
  sportRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: spacing.xs,
  },
  sportLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  sportIcon: {
    width: 28,
    height: 28,
    borderRadius: 14,
    justifyContent: 'center',
    alignItems: 'center',
  },
  sportSessions: {
    ...typography.styles.caption,
    color: colors.neutral.gray[600],
    fontWeight: '500',
  },
  sportRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  sportDuration: {
    ...typography.styles.body,
    color: colors.secondary[800],
    fontWeight: '600',
  },
  sportDistance: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  zonesSection: {
    marginBottom: spacing.md,
  },
  sectionLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    marginBottom: spacing.xs,
  },
  conformitySection: {
    borderTopWidth: 1,
    borderTopColor: colors.neutral.gray[100],
    paddingTop: spacing.sm,
  },
  conformityBar: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  conformityTrack: {
    flex: 1,
    height: 8,
    backgroundColor: colors.neutral.gray[100],
    borderRadius: 4,
    overflow: 'hidden',
  },
  conformityFill: {
    height: '100%',
    borderRadius: 4,
  },
  conformityValue: {
    ...typography.styles.label,
    fontWeight: '700',
    minWidth: 40,
    textAlign: 'right',
  },
});

export default WeekSummary;
