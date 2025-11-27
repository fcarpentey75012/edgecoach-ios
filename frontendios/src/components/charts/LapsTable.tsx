/**
 * Tableau des tours/laps
 * Affiche les détails de chaque lap/kilomètre de la séance
 */

import React from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { colors, spacing, typography } from '../../theme';

interface LapData {
  distance?: number;
  duration?: number;
  avg_speed?: number;
  avg_speed_kmh?: number;
  max_speed?: number;
  hr_avg?: number;
  hr_max?: number;
  cadence_avg?: number;
  ascent?: number;
  descent?: number;
  calories?: number;
  tpx_ext_stats?: {
    Watts?: { avg?: number; max?: number };
  };
}

interface LapsTableProps {
  laps: LapData[];
  discipline: 'cyclisme' | 'course' | 'natation' | 'autre';
  compact?: boolean;
}

// Formater la durée en MM:SS ou HH:MM:SS
const formatDuration = (seconds?: number): string => {
  if (!seconds) return '--:--';
  const hours = Math.floor(seconds / 3600);
  const mins = Math.floor((seconds % 3600) / 60);
  const secs = Math.floor(seconds % 60);

  if (hours > 0) {
    return `${hours}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }
  return `${mins}:${secs.toString().padStart(2, '0')}`;
};

// Formater le pace en min:sec/km
const formatPace = (speedKmh?: number): string => {
  if (!speedKmh || speedKmh <= 0) return '--:--';
  const paceMinKm = 60 / speedKmh;
  const minutes = Math.floor(paceMinKm);
  const seconds = Math.round((paceMinKm - minutes) * 60);
  return `${minutes}:${seconds.toString().padStart(2, '0')}`;
};

// Formater la distance
const formatDistance = (meters?: number): string => {
  if (!meters) return '-';
  if (meters >= 1000) {
    return `${(meters / 1000).toFixed(2)} km`;
  }
  return `${Math.round(meters)} m`;
};

const LapsTable: React.FC<LapsTableProps> = ({
  laps,
  discipline,
  compact = false,
}) => {
  if (!laps || laps.length === 0) {
    return (
      <View style={styles.container}>
        <Text style={styles.title}>Tours / Segments</Text>
        <View style={styles.noDataContainer}>
          <Text style={styles.noDataText}>Pas de données de tours</Text>
        </View>
      </View>
    );
  }

  // Déterminer les colonnes à afficher selon la discipline
  const isRunning = discipline === 'course';
  const isCycling = discipline === 'cyclisme';

  // Calculer les statistiques pour la mise en évidence
  const avgPaces = laps.map(lap => {
    const speed = lap.avg_speed_kmh || (lap.avg_speed ? lap.avg_speed * 3.6 : 0);
    return speed > 0 ? 60 / speed : 0;
  }).filter(p => p > 0);

  const avgPace = avgPaces.length > 0
    ? avgPaces.reduce((a, b) => a + b, 0) / avgPaces.length
    : 0;

  // Trouver le meilleur et pire lap
  const bestLapIndex = avgPaces.indexOf(Math.min(...avgPaces));
  const worstLapIndex = avgPaces.indexOf(Math.max(...avgPaces));

  return (
    <View style={[styles.container, compact && styles.containerCompact]}>
      <View style={styles.header}>
        <Icon name="flag-outline" size={18} color={colors.primary[600]} />
        <Text style={styles.title}>Tours / Segments</Text>
        <Text style={styles.lapCount}>{laps.length} tours</Text>
      </View>

      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={true}
        style={styles.tableScroll}
      >
        <View style={styles.table}>
          {/* En-tête du tableau */}
          <View style={styles.tableHeader}>
            <Text style={[styles.headerCell, styles.cellLap]}>#</Text>
            <Text style={[styles.headerCell, styles.cellDistance]}>Dist.</Text>
            <Text style={[styles.headerCell, styles.cellDuration]}>Durée</Text>
            {isRunning && (
              <Text style={[styles.headerCell, styles.cellPace]}>Allure</Text>
            )}
            {isCycling && (
              <Text style={[styles.headerCell, styles.cellSpeed]}>Vit.</Text>
            )}
            <Text style={[styles.headerCell, styles.cellHr]}>FC</Text>
            {isCycling && (
              <Text style={[styles.headerCell, styles.cellPower]}>Puiss.</Text>
            )}
            <Text style={[styles.headerCell, styles.cellElevation]}>D+</Text>
          </View>

          {/* Lignes du tableau */}
          {laps.map((lap, index) => {
            const speed = lap.avg_speed_kmh || (lap.avg_speed ? lap.avg_speed * 3.6 : 0);
            const isBest = index === bestLapIndex;
            const isWorst = index === worstLapIndex && laps.length > 2;
            const power = lap.tpx_ext_stats?.Watts?.avg;

            return (
              <View
                key={index}
                style={[
                  styles.tableRow,
                  index % 2 === 0 && styles.tableRowEven,
                  isBest && styles.tableRowBest,
                  isWorst && styles.tableRowWorst,
                ]}
              >
                <View style={styles.cellLap}>
                  <Text style={styles.lapNumber}>{index + 1}</Text>
                  {isBest && <Icon name="trophy" size={12} color={colors.status.success} />}
                </View>
                <Text style={[styles.cell, styles.cellDistance]}>
                  {formatDistance(lap.distance)}
                </Text>
                <Text style={[styles.cell, styles.cellDuration]}>
                  {formatDuration(lap.duration)}
                </Text>
                {isRunning && (
                  <Text style={[
                    styles.cell,
                    styles.cellPace,
                    isBest && styles.bestValue,
                    isWorst && styles.worstValue,
                  ]}>
                    {formatPace(speed)}
                  </Text>
                )}
                {isCycling && (
                  <Text style={[styles.cell, styles.cellSpeed]}>
                    {speed > 0 ? `${speed.toFixed(1)}` : '-'}
                  </Text>
                )}
                <Text style={[styles.cell, styles.cellHr]}>
                  {lap.hr_avg ? `${Math.round(lap.hr_avg)}` : '-'}
                </Text>
                {isCycling && (
                  <Text style={[styles.cell, styles.cellPower]}>
                    {power ? `${Math.round(power)}W` : '-'}
                  </Text>
                )}
                <Text style={[styles.cell, styles.cellElevation]}>
                  {lap.ascent ? `+${Math.round(lap.ascent)}` : '-'}
                </Text>
              </View>
            );
          })}

          {/* Ligne de totaux */}
          <View style={[styles.tableRow, styles.tableRowTotal]}>
            <Text style={[styles.cell, styles.cellLap, styles.totalLabel]}>Total</Text>
            <Text style={[styles.cell, styles.cellDistance, styles.totalValue]}>
              {formatDistance(laps.reduce((sum, lap) => sum + (lap.distance || 0), 0))}
            </Text>
            <Text style={[styles.cell, styles.cellDuration, styles.totalValue]}>
              {formatDuration(laps.reduce((sum, lap) => sum + (lap.duration || 0), 0))}
            </Text>
            {isRunning && (
              <Text style={[styles.cell, styles.cellPace, styles.totalValue]}>
                {avgPace > 0 ? formatPace(60 / avgPace) : '-'}
              </Text>
            )}
            {isCycling && (
              <Text style={[styles.cell, styles.cellSpeed, styles.totalValue]}>
                {'-'}
              </Text>
            )}
            <Text style={[styles.cell, styles.cellHr, styles.totalValue]}>
              {'-'}
            </Text>
            {isCycling && (
              <Text style={[styles.cell, styles.cellPower, styles.totalValue]}>
                {'-'}
              </Text>
            )}
            <Text style={[styles.cell, styles.cellElevation, styles.totalValue]}>
              +{Math.round(laps.reduce((sum, lap) => sum + (lap.ascent || 0), 0))}
            </Text>
          </View>
        </View>
      </ScrollView>

      {/* Légende */}
      <View style={styles.legend}>
        <View style={styles.legendItem}>
          <View style={[styles.legendDot, { backgroundColor: colors.status.success + '30' }]} />
          <Text style={styles.legendText}>Meilleur tour</Text>
        </View>
        {laps.length > 2 && (
          <View style={styles.legendItem}>
            <View style={[styles.legendDot, { backgroundColor: colors.status.error + '20' }]} />
            <Text style={styles.legendText}>Plus lent</Text>
          </View>
        )}
      </View>
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
  containerCompact: {
    padding: spacing.sm,
    marginBottom: spacing.sm,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: spacing.md,
  },
  title: {
    ...typography.styles.label,
    color: colors.secondary[800],
    fontWeight: '600',
    flex: 1,
  },
  lapCount: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  tableScroll: {
    marginBottom: spacing.sm,
  },
  table: {
    minWidth: '100%',
  },
  tableHeader: {
    flexDirection: 'row',
    backgroundColor: colors.neutral.gray[100],
    paddingVertical: spacing.sm,
    borderRadius: spacing.borderRadius.sm,
  },
  headerCell: {
    ...typography.styles.caption,
    color: colors.neutral.gray[600],
    fontWeight: '600',
    textAlign: 'center',
  },
  tableRow: {
    flexDirection: 'row',
    paddingVertical: spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: colors.neutral.gray[100],
    alignItems: 'center',
  },
  tableRowEven: {
    backgroundColor: colors.neutral.gray[50],
  },
  tableRowBest: {
    backgroundColor: colors.status.success + '15',
  },
  tableRowWorst: {
    backgroundColor: colors.status.error + '10',
  },
  tableRowTotal: {
    backgroundColor: colors.primary[50],
    borderBottomWidth: 0,
    marginTop: spacing.xs,
    borderRadius: spacing.borderRadius.sm,
  },
  cell: {
    ...typography.styles.caption,
    color: colors.secondary[800],
    textAlign: 'center',
  },
  cellLap: {
    width: 40,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 2,
  },
  lapNumber: {
    ...typography.styles.caption,
    color: colors.secondary[800],
    fontWeight: '600',
  },
  cellDistance: {
    width: 70,
  },
  cellDuration: {
    width: 65,
  },
  cellPace: {
    width: 55,
    fontWeight: '600',
  },
  cellSpeed: {
    width: 50,
  },
  cellHr: {
    width: 45,
  },
  cellPower: {
    width: 50,
  },
  cellElevation: {
    width: 45,
  },
  bestValue: {
    color: colors.status.success,
    fontWeight: '700',
  },
  worstValue: {
    color: colors.status.error,
  },
  totalLabel: {
    fontWeight: '700',
    color: colors.primary[700],
  },
  totalValue: {
    fontWeight: '700',
    color: colors.primary[700],
  },
  legend: {
    flexDirection: 'row',
    gap: spacing.md,
    marginTop: spacing.xs,
  },
  legendItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  legendDot: {
    width: 12,
    height: 12,
    borderRadius: 2,
  },
  legendText: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  noDataContainer: {
    height: 80,
    justifyContent: 'center',
    alignItems: 'center',
  },
  noDataText: {
    ...typography.styles.body,
    color: colors.neutral.gray[400],
  },
});

export default LapsTable;
