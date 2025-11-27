/**
 * Graphique du profil d'altitude
 * Utilise les charts natifs SwiftUI iOS 16+ avec fallback
 */

import React, { useMemo } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { NativeLineChart } from './native';
import { colors, spacing, typography } from '../../theme';

interface DataPoint {
  altitude?: number;
  enhanced_altitude?: number;
  distance?: number;
  time?: string;
}

interface ElevationChartProps {
  recordData: DataPoint[];
  elevationGain?: number | null;
  elevationLoss?: number | null;
  compact?: boolean;
}

const ElevationChart: React.FC<ElevationChartProps> = ({
  recordData,
  elevationGain,
  elevationLoss,
  compact = false,
}) => {
  const chartData = useMemo(() => {
    if (!recordData || recordData.length === 0) return [];

    const sampleRate = Math.max(1, Math.floor(recordData.length / 100));
    const sampled = recordData.filter((_, index) => index % sampleRate === 0);

    return sampled
      .map(point => {
        const altitude = point.enhanced_altitude || point.altitude || 0;
        return { value: altitude };
      })
      .filter(point => !isNaN(point.value) && point.value > 0);
  }, [recordData]);

  if (chartData.length === 0) {
    return (
      <View style={[styles.container, compact && styles.containerCompact]}>
        <Text style={styles.title}>Profil d'altitude</Text>
        <View style={styles.noDataContainer}>
          <Text style={styles.noDataText}>Pas de données d'altitude</Text>
        </View>
      </View>
    );
  }

  const chartHeight = compact ? 100 : 150;

  return (
    <View style={[styles.container, compact && styles.containerCompact]}>
      <View style={styles.header}>
        <Text style={styles.title}>Profil d'altitude</Text>
        <View style={styles.statsRow}>
          {elevationGain !== null && elevationGain !== undefined && (
            <View style={styles.stat}>
              <Text style={styles.statLabel}>D+</Text>
              <Text style={[styles.statValue, styles.elevationGain]}>{elevationGain}m</Text>
            </View>
          )}
          {elevationLoss !== null && elevationLoss !== undefined && (
            <View style={styles.stat}>
              <Text style={styles.statLabel}>D-</Text>
              <Text style={[styles.statValue, styles.elevationLoss]}>{elevationLoss}m</Text>
            </View>
          )}
        </View>
      </View>

      <View style={styles.chartContainer}>
        <NativeLineChart
          data={chartData}
          color={colors.sports.cycling}
          height={chartHeight}
          showGradient
          showInteraction
          style={styles.chart}
        />
      </View>
      <Text style={styles.axisNote}>Glissez pour voir l'altitude</Text>
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
  },
  elevationGain: {
    color: colors.status.success,
  },
  elevationLoss: {
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

export default ElevationChart;
