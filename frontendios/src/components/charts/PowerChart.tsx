/**
 * Graphique de la courbe de puissance (cyclisme)
 * Utilise les charts natifs SwiftUI iOS 16+ avec fallback
 */

import React, { useMemo } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { NativeLineChart } from './native';
import { colors, spacing, typography } from '../../theme';

interface DataPoint {
  Watts?: number;
  power?: number;
  distance?: number;
  time?: string;
}

interface PowerChartProps {
  recordData: DataPoint[];
  avgPower?: number | null;
  maxPower?: number | null;
  normalizedPower?: number | null;
  compact?: boolean;
}

const PowerChart: React.FC<PowerChartProps> = ({
  recordData,
  avgPower,
  maxPower,
  normalizedPower,
  compact = false,
}) => {
  const chartData = useMemo(() => {
    if (!recordData || recordData.length === 0) return [];

    const sampleRate = Math.max(1, Math.floor(recordData.length / 100));
    const sampled = recordData.filter((_, index) => index % sampleRate === 0);

    const windowSize = 3;
    return sampled
      .map((point, index, arr) => {
        const power = point.Watts || point.power || 0;
        if (power === 0) return null;

        const start = Math.max(0, index - windowSize);
        const end = Math.min(arr.length - 1, index + windowSize);
        let sum = 0;
        let count = 0;
        for (let i = start; i <= end; i++) {
          const p = arr[i].Watts || arr[i].power || 0;
          if (p > 0) {
            sum += p;
            count++;
          }
        }
        const smoothedPower = count > 0 ? sum / count : power;

        return { value: smoothedPower };
      })
      .filter(
        (point): point is { value: number } =>
          point !== null && !isNaN(point.value) && point.value > 0
      );
  }, [recordData]);

  if (chartData.length === 0) {
    return (
      <View style={[styles.container, compact && styles.containerCompact]}>
        <Text style={styles.title}>Puissance</Text>
        <View style={styles.noDataContainer}>
          <Text style={styles.noDataText}>Pas de données de puissance</Text>
        </View>
      </View>
    );
  }

  const chartHeight = compact ? 100 : 150;

  return (
    <View style={[styles.container, compact && styles.containerCompact]}>
      <View style={styles.header}>
        <Text style={styles.title}>Puissance</Text>
        <View style={styles.statsRow}>
          {avgPower !== null && avgPower !== undefined && (
            <View style={styles.stat}>
              <Text style={styles.statLabel}>Moy</Text>
              <Text style={styles.statValue}>{avgPower}W</Text>
            </View>
          )}
          {normalizedPower !== null && normalizedPower !== undefined && (
            <View style={styles.stat}>
              <Text style={styles.statLabel}>NP</Text>
              <Text style={[styles.statValue, styles.npValue]}>{normalizedPower}W</Text>
            </View>
          )}
          {maxPower !== null && maxPower !== undefined && (
            <View style={styles.stat}>
              <Text style={styles.statLabel}>Max</Text>
              <Text style={[styles.statValue, styles.maxValue]}>{maxPower}W</Text>
            </View>
          )}
        </View>
      </View>

      <View style={styles.chartContainer}>
        <NativeLineChart
          data={chartData}
          color={colors.status.warning}
          height={chartHeight}
          showGradient
          showInteraction
          style={styles.chart}
        />
      </View>
      <Text style={styles.axisNote}>Glissez pour voir les valeurs</Text>
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
  npValue: {
    color: colors.primary[600],
  },
  maxValue: {
    color: colors.status.error,
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
  axisNote: {
    ...typography.styles.caption,
    color: colors.neutral.gray[400],
    fontSize: 10,
    marginTop: spacing.xs,
    textAlign: 'center',
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

export default PowerChart;
