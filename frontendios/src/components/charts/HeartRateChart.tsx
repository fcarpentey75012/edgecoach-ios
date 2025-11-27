/**
 * Graphique de fréquence cardiaque
 * Utilise les charts natifs SwiftUI iOS 16+ avec fallback
 * Affiche la FC sur la durée + zones FC en pie chart
 */

import React, { useMemo } from 'react';
import { View, Text, StyleSheet, Dimensions } from 'react-native';
import { NativeLineChart, NativeDonutChart } from './native';
import { colors, spacing, typography } from '../../theme';
import { ActivityZone } from '../../services/activitiesService';

const SCREEN_WIDTH = Dimensions.get('window').width;

interface DataPoint {
  heart_rate?: number;
  hr?: number;
  distance?: number;
  time?: string;
}

interface HeartRateChartProps {
  recordData?: DataPoint[];
  zones?: ActivityZone[] | null;
  avgHr?: number | null;
  maxHr?: number | null;
  compact?: boolean;
  showLineChart?: boolean;
  showZonesPie?: boolean;
}

const HeartRateChart: React.FC<HeartRateChartProps> = ({
  recordData = [],
  zones,
  avgHr,
  maxHr,
  compact = false,
  showLineChart = true,
  showZonesPie = true,
}) => {
  // Préparer les données pour le graphique linéaire
  const chartData = useMemo(() => {
    if (!recordData || recordData.length === 0) return [];

    const sampleRate = Math.max(1, Math.floor(recordData.length / 100));
    const sampled = recordData.filter((_, index) => index % sampleRate === 0);

    return sampled
      .map(point => {
        const hr = point.heart_rate || point.hr || 0;
        if (hr === 0) return null;
        return { value: hr };
      })
      .filter((point): point is { value: number } => point !== null && !isNaN(point.value));
  }, [recordData]);

  // Préparer les données pour le pie chart des zones
  const pieZones = useMemo(() => {
    if (!zones || !Array.isArray(zones) || zones.length === 0) return [];
    return zones
      .filter(z => z && typeof z.percentage === 'number' && z.percentage > 0)
      .map(zone => ({
        zone: zone.zone,
        percentage: zone.percentage,
        time_seconds: zone.time_seconds || 0,
      }));
  }, [zones]);

  const hasLineData = chartData.length > 0 && showLineChart;
  const hasPieData = pieZones.length > 0 && showZonesPie;

  if (!hasLineData && !hasPieData) {
    return (
      <View style={[styles.container, compact && styles.containerCompact]}>
        <Text style={styles.title}>Fréquence cardiaque</Text>
        <View style={styles.noDataContainer}>
          <Text style={styles.noDataText}>Pas de données de FC</Text>
        </View>
      </View>
    );
  }

  const chartHeight = compact ? 80 : 120;

  return (
    <View style={[styles.container, compact && styles.containerCompact]}>
      <View style={styles.header}>
        <Text style={styles.title}>Fréquence cardiaque</Text>
        <View style={styles.statsRow}>
          {avgHr !== null && avgHr !== undefined && (
            <View style={styles.stat}>
              <Text style={styles.statLabel}>Moy</Text>
              <Text style={styles.statValue}>{avgHr} bpm</Text>
            </View>
          )}
          {maxHr !== null && maxHr !== undefined && (
            <View style={styles.stat}>
              <Text style={styles.statLabel}>Max</Text>
              <Text style={[styles.statValue, styles.maxValue]}>{maxHr} bpm</Text>
            </View>
          )}
        </View>
      </View>

      <View style={styles.chartsWrapper}>
        {/* Graphique linéaire FC */}
        {hasLineData && (
          <View style={[styles.chartContainer, hasPieData && styles.chartContainerHalf]}>
            <NativeLineChart
              data={chartData}
              color={colors.status.error}
              height={chartHeight}
              showGradient
              showInteraction
              style={styles.lineChart}
            />
          </View>
        )}

        {/* Pie chart des zones */}
        {hasPieData && (
          <View style={[styles.pieContainer, hasLineData && styles.pieContainerHalf]}>
            <NativeDonutChart
              zones={pieZones}
              size={compact ? 70 : 90}
              innerRadius={0.5}
              showLegend={true}
              compact={compact}
            />
          </View>
        )}
      </View>

      {hasLineData && (
        <Text style={styles.axisNote}>Glissez sur la courbe pour voir les valeurs</Text>
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
  maxValue: {
    color: colors.status.error,
  },
  chartsWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  chartContainer: {
    flex: 1,
    overflow: 'hidden',
  },
  chartContainerHalf: {
    flex: 0.55,
  },
  lineChart: {
    marginBottom: 0,
    padding: 0,
    shadowOpacity: 0,
    elevation: 0,
  },
  pieContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  pieContainerHalf: {
    flex: 0.45,
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

export default HeartRateChart;
