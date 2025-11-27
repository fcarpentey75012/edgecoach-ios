/**
 * Graphique de vitesse pour le cyclisme
 * Utilise les charts natifs SwiftUI iOS 16+ avec fallback
 */

import React, { useMemo } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { NativeLineChart } from './native';
import { colors, spacing, typography } from '../../theme';

interface DataPoint {
  Speed?: number;
  enhanced_speed?: number;
  speed?: number;
  distance?: number;
  time?: string;
}

interface SpeedChartProps {
  recordData: DataPoint[];
  avgSpeed?: number | null;
  maxSpeed?: number | null;
  compact?: boolean;
}

const SpeedChart: React.FC<SpeedChartProps> = ({
  recordData,
  avgSpeed,
  maxSpeed,
  compact = false,
}) => {
  const chartData = useMemo(() => {
    if (!recordData || recordData.length === 0) return [];

    const sampleRate = Math.max(1, Math.floor(recordData.length / 100));
    const sampled = recordData.filter((_, index) => index % sampleRate === 0);

    const windowSize = 3;
    return sampled
      .map((point, index, arr) => {
        let speed = point.Speed || point.enhanced_speed || point.speed || 0;

        if (point.enhanced_speed && !point.Speed) {
          speed = point.enhanced_speed * 3.6;
        }

        if (speed <= 0) return null;

        const start = Math.max(0, index - windowSize);
        const end = Math.min(arr.length - 1, index + windowSize);
        let sumSpeed = 0;
        let count = 0;
        for (let i = start; i <= end; i++) {
          let s = arr[i].Speed || arr[i].enhanced_speed || arr[i].speed || 0;
          if (arr[i].enhanced_speed && !arr[i].Speed) {
            s = arr[i].enhanced_speed! * 3.6;
          }
          if (s > 0) {
            sumSpeed += s;
            count++;
          }
        }
        const avgSpd = count > 0 ? sumSpeed / count : speed;

        return { value: avgSpd };
      })
      .filter(
        (point): point is { value: number } =>
          point !== null && !isNaN(point.value) && point.value > 0
      );
  }, [recordData]);

  if (chartData.length === 0) {
    return (
      <View style={[styles.container, compact && styles.containerCompact]}>
        <Text style={styles.title}>Vitesse</Text>
        <View style={styles.noDataContainer}>
          <Text style={styles.noDataText}>Pas de données de vitesse</Text>
        </View>
      </View>
    );
  }

  const chartHeight = compact ? 100 : 130;

  return (
    <View style={[styles.container, compact && styles.containerCompact]}>
      <View style={styles.header}>
        <Text style={styles.title}>Vitesse</Text>
        <View style={styles.statsRow}>
          {avgSpeed !== null && avgSpeed !== undefined && (
            <View style={styles.stat}>
              <Text style={styles.statLabel}>Moy</Text>
              <Text style={styles.statValue}>{avgSpeed.toFixed(1)} km/h</Text>
            </View>
          )}
          {maxSpeed !== null && maxSpeed !== undefined && (
            <View style={styles.stat}>
              <Text style={styles.statLabel}>Max</Text>
              <Text style={[styles.statValue, styles.maxValue]}>{maxSpeed.toFixed(1)} km/h</Text>
            </View>
          )}
        </View>
      </View>

      <View style={styles.chartContainer}>
        <NativeLineChart
          data={chartData}
          color={colors.primary[500]}
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
  maxValue: {
    color: colors.primary[600],
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

export default SpeedChart;
