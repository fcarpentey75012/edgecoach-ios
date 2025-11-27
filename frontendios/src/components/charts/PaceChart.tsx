/**
 * Graphique de l'allure (pace) pour la course à pied
 * Utilise les charts natifs SwiftUI iOS 16+ avec fallback
 */

import React, { useMemo } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { NativeLineChart, NativeBarChart } from './native';
import { colors, spacing, typography } from '../../theme';

interface DataPoint {
  Speed?: number;
  enhanced_speed?: number;
  speed?: number;
  distance?: number;
  time?: string;
}

interface LapData {
  distance?: number;
  duration?: number;
  avg_speed?: number;
  avg_speed_kmh?: number;
}

interface PaceChartProps {
  recordData?: DataPoint[];
  laps?: LapData[];
  avgPace?: string | null;
  bestPace?: string | null;
  compact?: boolean;
  showLapBars?: boolean;
}

// Convertir vitesse km/h en pace min/km
const speedToPace = (speedKmh: number): number => {
  if (!speedKmh || speedKmh <= 0) return 0;
  return 60 / speedKmh;
};

// Formater le pace en min:sec
const formatPace = (paceMinKm: number): string => {
  if (!paceMinKm || paceMinKm <= 0 || paceMinKm > 20) return '--:--';
  const minutes = Math.floor(paceMinKm);
  const seconds = Math.round((paceMinKm - minutes) * 60);
  return `${minutes}:${seconds.toString().padStart(2, '0')}`;
};

const PaceChart: React.FC<PaceChartProps> = ({
  recordData = [],
  laps = [],
  avgPace,
  bestPace,
  compact = false,
  showLapBars = true,
}) => {
  // Préparer les données pour le graphique linéaire (pace par distance)
  const chartData = useMemo(() => {
    if (!recordData || recordData.length === 0) return [];

    const sampleRate = Math.max(1, Math.floor(recordData.length / 80));
    const sampled = recordData.filter((_, index) => index % sampleRate === 0);

    // Moyenne mobile pour lisser
    const windowSize = 5;
    return sampled
      .map((point, index, arr) => {
        const speedKmh = point.Speed || point.enhanced_speed || point.speed || 0;
        if (speedKmh <= 0) return null;

        const start = Math.max(0, index - windowSize);
        const end = Math.min(arr.length - 1, index + windowSize);
        let sumSpeed = 0;
        let count = 0;
        for (let i = start; i <= end; i++) {
          const s = arr[i].Speed || arr[i].enhanced_speed || arr[i].speed || 0;
          if (s > 0) {
            sumSpeed += s;
            count++;
          }
        }
        const avgSpeed = count > 0 ? sumSpeed / count : speedKmh;
        const pace = speedToPace(avgSpeed);

        // Filtrer les valeurs aberrantes
        if (pace <= 2 || pace > 15) return null;

        return { value: pace };
      })
      .filter(
        (point): point is { value: number } => point !== null && !isNaN(point.value)
      );
  }, [recordData]);

  // Préparer les données pour les barres par lap
  const barData = useMemo(() => {
    if (!laps || laps.length === 0) return [];

    const avgLapPace =
      laps.reduce((sum, lap) => {
        const speed = lap.avg_speed_kmh || (lap.avg_speed ? lap.avg_speed * 3.6 : 0);
        return sum + (speed > 0 ? speedToPace(speed) : 0);
      }, 0) / laps.length;

    return laps
      .map((lap, index) => {
        const speedKmh = lap.avg_speed_kmh || (lap.avg_speed ? lap.avg_speed * 3.6 : 0);
        const pace = speedToPace(speedKmh);

        if (pace <= 2 || pace > 15) return null;

        return {
          value: pace,
          label: `${index + 1}`,
        };
      })
      .filter((d): d is { value: number; label: string } => d !== null);
  }, [laps]);

  const hasChartData = chartData.length > 0;
  const hasBarData = barData.length > 0 && showLapBars;

  if (!hasChartData && !hasBarData) {
    return (
      <View style={[styles.container, compact && styles.containerCompact]}>
        <Text style={styles.title}>Allure</Text>
        <View style={styles.noDataContainer}>
          <Text style={styles.noDataText}>Pas de données d'allure</Text>
        </View>
      </View>
    );
  }

  // Calculer la moyenne pour les barres
  const avgBarValue =
    barData.length > 0
      ? barData.reduce((sum, d) => sum + d.value, 0) / barData.length
      : undefined;

  return (
    <View style={[styles.container, compact && styles.containerCompact]}>
      <View style={styles.header}>
        <Text style={styles.title}>Allure</Text>
        <View style={styles.statsRow}>
          {avgPace && (
            <View style={styles.stat}>
              <Text style={styles.statLabel}>Moy</Text>
              <Text style={styles.statValue}>{avgPace}/km</Text>
            </View>
          )}
          {bestPace && (
            <View style={styles.stat}>
              <Text style={styles.statLabel}>Meilleur</Text>
              <Text style={[styles.statValue, styles.bestValue]}>{bestPace}/km</Text>
            </View>
          )}
        </View>
      </View>

      {/* Graphique linéaire de l'allure */}
      {hasChartData && (
        <View style={styles.chartContainer}>
          <NativeLineChart
            data={chartData}
            color={colors.sports.running}
            height={compact ? 80 : 120}
            showGradient
            showInteraction
            style={styles.chart}
          />
        </View>
      )}

      {/* Barres par lap */}
      {hasBarData && (
        <View style={styles.lapsSection}>
          <NativeBarChart
            data={barData}
            color={colors.sports.running}
            height={compact ? 60 : 80}
            avgValue={avgBarValue}
            title="Allure par kilomètre"
            formatLabel={formatPace}
            compact={compact}
            style={styles.barChart}
          />
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
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 8,
    elevation: 2,
  },
  containerCompact: {
    padding: spacing.sm,
    marginBottom: spacing.sm,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.sm,
  },
  title: {
    ...typography.styles.label,
    color: colors.secondary[800],
    fontWeight: '600',
  },
  statsRow: {
    flexDirection: 'row',
    gap: spacing.md,
  },
  stat: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  statLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  statValue: {
    ...typography.styles.label,
    fontWeight: '700',
    color: colors.secondary[800],
  },
  bestValue: {
    color: colors.status.success,
  },
  chartContainer: {
    alignItems: 'center',
    overflow: 'hidden',
  },
  chart: {
    marginBottom: 0,
    padding: 0,
    shadowOpacity: 0,
    elevation: 0,
  },
  lapsSection: {
    marginTop: spacing.sm,
    borderTopWidth: 1,
    borderTopColor: colors.neutral.gray[100],
    paddingTop: spacing.sm,
  },
  barChart: {
    marginBottom: 0,
    padding: 0,
    shadowOpacity: 0,
    elevation: 0,
  },
  noDataContainer: {
    height: 100,
    justifyContent: 'center',
    alignItems: 'center',
  },
  noDataText: {
    ...typography.styles.body,
    color: colors.neutral.gray[400],
  },
});

export default PaceChart;
