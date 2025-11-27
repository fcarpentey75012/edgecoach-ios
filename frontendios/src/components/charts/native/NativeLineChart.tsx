/**
 * Wrapper React Native pour le graphique linéaire SwiftUI natif
 * iOS 16+ utilise Swift Charts, fallback sur react-native-gifted-charts sinon
 */

import React, { useMemo } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Platform,
  requireNativeComponent,
  ViewStyle,
  UIManager,
} from 'react-native';
import { LineChart } from 'react-native-gifted-charts';
import { colors, spacing, typography } from '../../../theme';

// Vérifier si le composant natif est disponible
const isNativeAvailable =
  Platform.OS === 'ios' &&
  parseInt(Platform.Version as string, 10) >= 16 &&
  UIManager.getViewManagerConfig('NativeLineChart') != null;

// Composant natif SwiftUI
const NativeLineChartView = isNativeAvailable
  ? requireNativeComponent<NativeLineChartProps>('NativeLineChart')
  : null;

interface DataPoint {
  value: number;
  [key: string]: any;
}

interface NativeLineChartProps {
  data: DataPoint[];
  color: string;
  showGradient?: boolean;
  chartHeight?: number;
  showInteraction?: boolean;
  style?: ViewStyle;
}

interface LineChartWrapperProps {
  data: DataPoint[];
  color?: string;
  height?: number;
  showGradient?: boolean;
  showInteraction?: boolean;
  title?: string;
  avgValue?: number | null;
  maxValue?: number | null;
  unit?: string;
  compact?: boolean;
  style?: ViewStyle;
}

const NativeLineChart: React.FC<LineChartWrapperProps> = ({
  data,
  color = colors.primary[500],
  height = 150,
  showGradient = true,
  showInteraction = true,
  title,
  avgValue,
  maxValue,
  unit = '',
  compact = false,
  style,
}) => {
  // Échantillonner les données si trop nombreuses
  const chartData = useMemo(() => {
    if (!data || data.length === 0) return [];
    const sampleRate = Math.max(1, Math.floor(data.length / 100));
    return data
      .filter((_, index) => index % sampleRate === 0)
      .filter(point => point.value != null && !isNaN(point.value) && point.value > 0);
  }, [data]);

  if (chartData.length === 0) {
    return (
      <View style={[styles.container, compact && styles.containerCompact, style]}>
        {title && <Text style={styles.title}>{title}</Text>}
        <View style={styles.noDataContainer}>
          <Text style={styles.noDataText}>Pas de données</Text>
        </View>
      </View>
    );
  }

  const chartHeight = compact ? 80 : height;

  // Utiliser le composant natif SwiftUI si disponible
  if (isNativeAvailable && NativeLineChartView) {
    return (
      <View style={[styles.container, compact && styles.containerCompact, style]}>
        {(title || avgValue != null || maxValue != null) && (
          <View style={styles.header}>
            {title && <Text style={styles.title}>{title}</Text>}
            <View style={styles.statsRow}>
              {avgValue != null && (
                <View style={styles.stat}>
                  <Text style={styles.statLabel}>Moy</Text>
                  <Text style={styles.statValue}>
                    {typeof avgValue === 'number' ? avgValue.toFixed(1) : avgValue}
                    {unit}
                  </Text>
                </View>
              )}
              {maxValue != null && (
                <View style={styles.stat}>
                  <Text style={styles.statLabel}>Max</Text>
                  <Text style={[styles.statValue, styles.maxValue]}>
                    {typeof maxValue === 'number' ? maxValue.toFixed(1) : maxValue}
                    {unit}
                  </Text>
                </View>
              )}
            </View>
          </View>
        )}
        <View style={styles.chartContainer}>
          <NativeLineChartView
            data={chartData}
            color={color}
            showGradient={showGradient}
            chartHeight={chartHeight}
            showInteraction={showInteraction}
            style={{ width: '100%', height: chartHeight }}
          />
        </View>
        {showInteraction && (
          <Text style={styles.axisNote}>Glissez pour voir les valeurs</Text>
        )}
      </View>
    );
  }

  // Fallback sur react-native-gifted-charts
  return (
    <View style={[styles.container, compact && styles.containerCompact, style]}>
      {(title || avgValue != null || maxValue != null) && (
        <View style={styles.header}>
          {title && <Text style={styles.title}>{title}</Text>}
          <View style={styles.statsRow}>
            {avgValue != null && (
              <View style={styles.stat}>
                <Text style={styles.statLabel}>Moy</Text>
                <Text style={styles.statValue}>
                  {typeof avgValue === 'number' ? avgValue.toFixed(1) : avgValue}
                  {unit}
                </Text>
              </View>
            )}
            {maxValue != null && (
              <View style={styles.stat}>
                <Text style={styles.statLabel}>Max</Text>
                <Text style={[styles.statValue, styles.maxValue]}>
                  {typeof maxValue === 'number' ? maxValue.toFixed(1) : maxValue}
                  {unit}
                </Text>
              </View>
            )}
          </View>
        </View>
      )}
      <View style={styles.chartContainer}>
        <LineChart
          data={chartData}
          height={chartHeight}
          color={color}
          areaChart={showGradient}
          startFillColor={showGradient ? color + '40' : undefined}
          endFillColor={showGradient ? color + '10' : undefined}
          hideDataPoints
          curved
          thickness={2}
          hideYAxisText
          hideAxesAndRules
          adjustToWidth
          initialSpacing={0}
          endSpacing={0}
        />
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
  chartContainer: {
    alignItems: 'center',
    overflow: 'hidden',
    borderRadius: spacing.borderRadius.md,
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

export default NativeLineChart;
