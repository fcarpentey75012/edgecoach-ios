/**
 * Composant de comparaison Prévu vs Réalisé
 * Affiche côte à côte les données planifiées et réalisées avec calcul des écarts
 */

import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { colors, spacing, typography } from '../../theme';

export interface ComparisonData {
  planned: {
    duration: string | null;
    distance: string | null;
    intensity: string | null;
  };
  actual: {
    duration: string | null;
    distance: string | null;
    tss: number | null;
  };
}

interface PlannedVsActualComparisonProps {
  data: ComparisonData;
  sportColor: string;
}

interface ComparisonRowProps {
  label: string;
  icon: string;
  planned: string | null;
  actual: string | null;
  unit?: string;
  showDiff?: boolean;
}

// Parser la durée en minutes
const parseDurationToMinutes = (duration: string | null): number | null => {
  if (!duration) return null;

  // Format "Xmin"
  const minMatch = duration.match(/^(\d+)min$/);
  if (minMatch) {
    return parseInt(minMatch[1], 10);
  }

  // Format "H:MM"
  const hourMinMatch = duration.match(/^(\d+):(\d+)$/);
  if (hourMinMatch) {
    return parseInt(hourMinMatch[1], 10) * 60 + parseInt(hourMinMatch[2], 10);
  }

  return null;
};

// Parser la distance en km
const parseDistanceToKm = (distance: string | null): number | null => {
  if (!distance) return null;

  // Format "X km" ou "X.X km"
  const kmMatch = distance.match(/^([\d.]+)\s*km$/);
  if (kmMatch) {
    return parseFloat(kmMatch[1]);
  }

  // Format "X m" (natation)
  const mMatch = distance.match(/^(\d+)\s*m$/);
  if (mMatch) {
    return parseInt(mMatch[1], 10) / 1000;
  }

  return null;
};

// Calculer le pourcentage de différence
const calculateDiffPercent = (planned: number | null, actual: number | null): number | null => {
  if (planned === null || actual === null || planned === 0) return null;
  return ((actual - planned) / planned) * 100;
};

// Formater la différence
const formatDiff = (diffPercent: number | null): { text: string; color: string; icon: string } | null => {
  if (diffPercent === null) return null;

  const absPercent = Math.abs(diffPercent);
  const sign = diffPercent >= 0 ? '+' : '';

  // Déterminer la couleur selon l'écart
  let color: string;
  let icon: string;

  if (absPercent <= 10) {
    color = colors.status.success; // Vert - dans les clous
    icon = 'checkmark-circle';
  } else if (absPercent <= 25) {
    color = colors.status.warning; // Orange - écart modéré
    icon = 'alert-circle';
  } else {
    color = colors.status.error; // Rouge - écart important
    icon = 'close-circle';
  }

  return {
    text: `${sign}${diffPercent.toFixed(0)}%`,
    color,
    icon,
  };
};

// Calculer le score de conformité global
const calculateConformityScore = (data: ComparisonData): number | null => {
  const diffs: number[] = [];

  // Durée
  const plannedMin = parseDurationToMinutes(data.planned.duration);
  const actualMin = parseDurationToMinutes(data.actual.duration);
  if (plannedMin && actualMin) {
    const diff = Math.abs(((actualMin - plannedMin) / plannedMin) * 100);
    diffs.push(Math.max(0, 100 - diff));
  }

  // Distance
  const plannedKm = parseDistanceToKm(data.planned.distance);
  const actualKm = parseDistanceToKm(data.actual.distance);
  if (plannedKm && actualKm) {
    const diff = Math.abs(((actualKm - plannedKm) / plannedKm) * 100);
    diffs.push(Math.max(0, 100 - diff));
  }

  if (diffs.length === 0) return null;

  return Math.round(diffs.reduce((a, b) => a + b, 0) / diffs.length);
};

const ComparisonRow: React.FC<ComparisonRowProps> = ({
  label,
  icon,
  planned,
  actual,
  showDiff = true,
}) => {
  // Calculer la différence pour durée et distance
  let diffInfo = null;
  if (showDiff && planned && actual) {
    const plannedMin = parseDurationToMinutes(planned);
    const actualMin = parseDurationToMinutes(actual);
    const plannedKm = parseDistanceToKm(planned);
    const actualKm = parseDistanceToKm(actual);

    if (plannedMin !== null && actualMin !== null) {
      diffInfo = formatDiff(calculateDiffPercent(plannedMin, actualMin));
    } else if (plannedKm !== null && actualKm !== null) {
      diffInfo = formatDiff(calculateDiffPercent(plannedKm, actualKm));
    }
  }

  return (
    <View style={styles.row}>
      <View style={styles.rowLabel}>
        <Icon name={icon} size={16} color={colors.neutral.gray[500]} />
        <Text style={styles.rowLabelText}>{label}</Text>
      </View>
      <View style={styles.rowValues}>
        <View style={styles.valueCell}>
          <Text style={styles.valueText}>{planned || '-'}</Text>
        </View>
        <View style={styles.valueCell}>
          <Text style={[styles.valueText, styles.actualValue]}>{actual || '-'}</Text>
        </View>
        <View style={styles.diffCell}>
          {diffInfo ? (
            <View style={[styles.diffBadge, { backgroundColor: diffInfo.color + '20' }]}>
              <Icon name={diffInfo.icon} size={12} color={diffInfo.color} />
              <Text style={[styles.diffText, { color: diffInfo.color }]}>{diffInfo.text}</Text>
            </View>
          ) : (
            <Text style={styles.noDiff}>-</Text>
          )}
        </View>
      </View>
    </View>
  );
};

const PlannedVsActualComparison: React.FC<PlannedVsActualComparisonProps> = ({
  data,
  sportColor,
}) => {
  const conformityScore = calculateConformityScore(data);

  // Déterminer la couleur du score
  const getScoreColor = (score: number | null): string => {
    if (score === null) return colors.neutral.gray[400];
    if (score >= 85) return colors.status.success;
    if (score >= 70) return colors.status.warning;
    return colors.status.error;
  };

  const scoreColor = getScoreColor(conformityScore);

  return (
    <View style={styles.container}>
      {/* En-tête avec score de conformité */}
      <View style={styles.header}>
        <View style={styles.headerLeft}>
          <Icon name="git-compare" size={20} color={sportColor} />
          <Text style={styles.headerTitle}>Prévu vs Réalisé</Text>
        </View>
        {conformityScore !== null && (
          <View style={[styles.scoreBadge, { backgroundColor: scoreColor + '20' }]}>
            <Icon name="checkmark-done" size={14} color={scoreColor} />
            <Text style={[styles.scoreText, { color: scoreColor }]}>
              {conformityScore}% conforme
            </Text>
          </View>
        )}
      </View>

      {/* Tableau de comparaison */}
      <View style={styles.table}>
        {/* En-têtes des colonnes */}
        <View style={styles.tableHeader}>
          <View style={styles.rowLabel} />
          <View style={styles.rowValues}>
            <View style={styles.valueCell}>
              <Text style={styles.columnHeader}>Prévu</Text>
            </View>
            <View style={styles.valueCell}>
              <Text style={styles.columnHeader}>Réalisé</Text>
            </View>
            <View style={styles.diffCell}>
              <Text style={styles.columnHeader}>Écart</Text>
            </View>
          </View>
        </View>

        {/* Lignes de données */}
        <ComparisonRow
          label="Durée"
          icon="time-outline"
          planned={data.planned.duration}
          actual={data.actual.duration}
        />
        <ComparisonRow
          label="Distance"
          icon="map-outline"
          planned={data.planned.distance}
          actual={data.actual.distance}
        />
        {data.planned.intensity && (
          <ComparisonRow
            label="Intensité"
            icon="flash-outline"
            planned={data.planned.intensity}
            actual={data.actual.tss ? `TSS ${data.actual.tss}` : null}
            showDiff={false}
          />
        )}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.md,
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
    gap: spacing.sm,
  },
  headerTitle: {
    ...typography.styles.label,
    color: colors.secondary[800],
    fontWeight: '600',
  },
  scoreBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: spacing.sm,
    paddingVertical: 4,
    borderRadius: spacing.borderRadius.full,
  },
  scoreText: {
    ...typography.styles.caption,
    fontWeight: '600',
  },
  table: {
    borderWidth: 1,
    borderColor: colors.neutral.gray[200],
    borderRadius: spacing.borderRadius.sm,
    overflow: 'hidden',
  },
  tableHeader: {
    flexDirection: 'row',
    backgroundColor: colors.neutral.gray[50],
    borderBottomWidth: 1,
    borderBottomColor: colors.neutral.gray[200],
    paddingVertical: spacing.sm,
    paddingHorizontal: spacing.sm,
  },
  columnHeader: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    fontWeight: '600',
    textAlign: 'center',
  },
  row: {
    flexDirection: 'row',
    borderBottomWidth: 1,
    borderBottomColor: colors.neutral.gray[100],
    paddingVertical: spacing.sm,
    paddingHorizontal: spacing.sm,
    alignItems: 'center',
  },
  rowLabel: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  rowLabelText: {
    ...typography.styles.caption,
    color: colors.secondary[700],
  },
  rowValues: {
    flex: 2,
    flexDirection: 'row',
    alignItems: 'center',
  },
  valueCell: {
    flex: 1,
    alignItems: 'center',
  },
  valueText: {
    ...typography.styles.body,
    color: colors.secondary[600],
    textAlign: 'center',
  },
  actualValue: {
    fontWeight: '600',
    color: colors.secondary[800],
  },
  diffCell: {
    flex: 1,
    alignItems: 'center',
  },
  diffBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
    paddingHorizontal: spacing.xs,
    paddingVertical: 2,
    borderRadius: spacing.borderRadius.sm,
  },
  diffText: {
    ...typography.styles.caption,
    fontWeight: '600',
  },
  noDiff: {
    ...typography.styles.caption,
    color: colors.neutral.gray[400],
  },
});

export default PlannedVsActualComparison;
