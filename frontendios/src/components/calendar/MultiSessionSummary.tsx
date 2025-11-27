/**
 * Widget de résumé multi-séances
 * Affiche un résumé agrégé quand un jour contient plusieurs séances
 * (double séance, brick triathlon, journée compétition)
 */

import React, { useMemo } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { colors, spacing, typography } from '../../theme';
import { Activity } from '../../services/activitiesService';

interface MultiSessionSummaryProps {
  sessions: Activity[];
  date: Date;
}

// Config des sports
const SPORT_CONFIG: Record<string, { icon: string; color: string; emoji: string }> = {
  cyclisme: { icon: 'bicycle', color: colors.sports.cycling, emoji: '🚴' },
  course: { icon: 'walk', color: colors.sports.running, emoji: '🏃' },
  natation: { icon: 'water', color: colors.sports.swimming, emoji: '🏊' },
  other: { icon: 'fitness', color: colors.neutral.gray[400], emoji: '🏋️' },
};

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

// Formater la durée
const formatDuration = (minutes: number): string => {
  const hours = Math.floor(minutes / 60);
  const mins = minutes % 60;
  if (hours === 0) return `${mins}min`;
  if (mins === 0) return `${hours}h`;
  return `${hours}h${mins.toString().padStart(2, '0')}`;
};

// Parser l'heure de début
const parseStartTime = (session: Activity): Date | null => {
  if (!session.date) return null;
  try {
    return new Date(session.date);
  } catch {
    return null;
  }
};

// Calculer le temps entre deux séances
const getTimeBetweenSessions = (session1: Activity, session2: Activity): number | null => {
  const time1 = parseStartTime(session1);
  const time2 = parseStartTime(session2);
  const duration1 = parseDurationToMinutes(session1.duration);

  if (!time1 || !time2 || duration1 === 0) return null;

  // Temps de fin de la première séance
  const endTime1 = new Date(time1.getTime() + duration1 * 60 * 1000);

  // Différence en minutes
  const diffMs = time2.getTime() - endTime1.getTime();
  const diffMinutes = Math.round(diffMs / (60 * 1000));

  return diffMinutes > 0 ? diffMinutes : null;
};

// Détecter si c'est un enchaînement brick
const detectBrickWorkout = (sessions: Activity[]): boolean => {
  if (sessions.length !== 2) return false;

  const disciplines = sessions.map(s => s.discipline);

  // Brick = vélo suivi de course ou natation suivie de vélo
  if (disciplines[0] === 'cyclisme' && disciplines[1] === 'course') return true;
  if (disciplines[0] === 'natation' && disciplines[1] === 'cyclisme') return true;

  return false;
};

const MultiSessionSummary: React.FC<MultiSessionSummaryProps> = ({ sessions, date }) => {
  // Ne pas afficher si moins de 2 séances
  if (sessions.length < 2) return null;

  // Calculer les totaux
  const totals = useMemo(() => {
    let totalDurationMinutes = 0;
    let totalTSS = 0;

    sessions.forEach(session => {
      totalDurationMinutes += parseDurationToMinutes(session.duration);
      if (session.loadCoggan) totalTSS += session.loadCoggan;
    });

    return { totalDurationMinutes, totalTSS };
  }, [sessions]);

  // Trier les séances par heure de début
  const sortedSessions = useMemo(() => {
    return [...sessions].sort((a, b) => {
      const timeA = parseStartTime(a);
      const timeB = parseStartTime(b);
      if (!timeA || !timeB) return 0;
      return timeA.getTime() - timeB.getTime();
    });
  }, [sessions]);

  // Détecter le type d'enchaînement
  const isBrick = detectBrickWorkout(sortedSessions);

  // Calculer le temps entre les séances
  const timeBetween = sortedSessions.length >= 2
    ? getTimeBetweenSessions(sortedSessions[0], sortedSessions[1])
    : null;

  // Générer le label d'enchaînement
  const getEnchaînementLabel = () => {
    const emojis = sortedSessions.map(s => {
      const config = SPORT_CONFIG[s.discipline] || SPORT_CONFIG.other;
      return config.emoji;
    });

    if (isBrick) {
      return `${emojis.join(' → ')} (brick)`;
    }

    return emojis.join(' → ');
  };

  return (
    <View style={styles.container}>
      {/* En-tête avec nombre de séances */}
      <View style={styles.header}>
        <View style={styles.headerLeft}>
          <Icon name="layers" size={18} color={colors.primary[600]} />
          <Text style={styles.headerTitle}>
            {sessions.length} séances
          </Text>
        </View>
        {isBrick && (
          <View style={styles.brickBadge}>
            <Icon name="flash" size={12} color={colors.sports.triathlon} />
            <Text style={styles.brickBadgeText}>Brick</Text>
          </View>
        )}
      </View>

      {/* Statistiques totales */}
      <View style={styles.statsRow}>
        <View style={styles.statItem}>
          <Icon name="time-outline" size={16} color={colors.primary[500]} />
          <Text style={styles.statValue}>{formatDuration(totals.totalDurationMinutes)}</Text>
          <Text style={styles.statLabel}>total</Text>
        </View>
        {totals.totalTSS > 0 && (
          <View style={styles.statItem}>
            <Icon name="barbell-outline" size={16} color={colors.status.error} />
            <Text style={styles.statValue}>{totals.totalTSS}</Text>
            <Text style={styles.statLabel}>TSS</Text>
          </View>
        )}
      </View>

      {/* Enchaînement */}
      <View style={styles.enchaînementRow}>
        <Text style={styles.enchaînementLabel}>Enchaînement:</Text>
        <Text style={styles.enchaînementValue}>{getEnchaînementLabel()}</Text>
      </View>

      {/* Temps entre les séances */}
      {timeBetween !== null && (
        <View style={styles.recoveryRow}>
          <Icon name="hourglass-outline" size={14} color={colors.neutral.gray[500]} />
          <Text style={styles.recoveryText}>
            {timeBetween < 60
              ? `${timeBetween}min entre les séances`
              : `${Math.floor(timeBetween / 60)}h${timeBetween % 60 > 0 ? (timeBetween % 60).toString().padStart(2, '0') : ''} entre les séances`
            }
          </Text>
        </View>
      )}

      {/* Liste des séances */}
      <View style={styles.sessionsList}>
        {sortedSessions.map((session, index) => {
          const config = SPORT_CONFIG[session.discipline] || SPORT_CONFIG.other;
          const duration = parseDurationToMinutes(session.duration);

          return (
            <View key={session.id} style={styles.sessionItem}>
              <View style={styles.sessionNumber}>
                <Text style={styles.sessionNumberText}>{index + 1}</Text>
              </View>
              <View style={[styles.sessionIcon, { backgroundColor: config.color + '20' }]}>
                <Icon name={config.icon} size={14} color={config.color} />
              </View>
              <View style={styles.sessionInfo}>
                <Text style={styles.sessionTitle} numberOfLines={1}>
                  {session.title}
                </Text>
                <Text style={styles.sessionMeta}>
                  {formatDuration(duration)}
                  {session.loadCoggan ? ` · TSS ${session.loadCoggan}` : ''}
                </Text>
              </View>
              <Icon name="chevron-forward" size={16} color={colors.neutral.gray[300]} />
            </View>
          );
        })}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.md,
    marginBottom: spacing.sm,
    borderWidth: 1,
    borderColor: colors.primary[100],
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.sm,
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
  brickBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: colors.sports.triathlon + '20',
    paddingHorizontal: spacing.sm,
    paddingVertical: 2,
    borderRadius: spacing.borderRadius.full,
  },
  brickBadgeText: {
    ...typography.styles.caption,
    color: colors.sports.triathlon,
    fontWeight: '600',
  },
  statsRow: {
    flexDirection: 'row',
    gap: spacing.lg,
    marginBottom: spacing.sm,
    paddingBottom: spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: colors.neutral.gray[100],
  },
  statItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  statValue: {
    ...typography.styles.label,
    color: colors.secondary[800],
    fontWeight: '700',
  },
  statLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  enchaînementRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
    marginBottom: spacing.xs,
  },
  enchaînementLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  enchaînementValue: {
    ...typography.styles.body,
    color: colors.secondary[800],
  },
  recoveryRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
    marginBottom: spacing.sm,
  },
  recoveryText: {
    ...typography.styles.caption,
    color: colors.neutral.gray[600],
  },
  sessionsList: {
    gap: spacing.xs,
  },
  sessionItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    paddingVertical: spacing.xs,
  },
  sessionNumber: {
    width: 20,
    height: 20,
    borderRadius: 10,
    backgroundColor: colors.neutral.gray[100],
    justifyContent: 'center',
    alignItems: 'center',
  },
  sessionNumberText: {
    ...typography.styles.caption,
    color: colors.neutral.gray[600],
    fontWeight: '600',
  },
  sessionIcon: {
    width: 28,
    height: 28,
    borderRadius: 14,
    justifyContent: 'center',
    alignItems: 'center',
  },
  sessionInfo: {
    flex: 1,
  },
  sessionTitle: {
    ...typography.styles.body,
    color: colors.secondary[800],
    fontSize: 13,
  },
  sessionMeta: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    fontSize: 11,
  },
});

export default MultiSessionSummary;
