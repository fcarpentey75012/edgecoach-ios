/**
 * Wrapper React Native pour le graphique en barres SwiftUI natif
 * Utilisé pour les laps/splits
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
import { BarChart } from 'react-native-gifted-charts';
import { colors, spacing, typography } from '../../../theme';

// Vérifier si le composant natif est disponible
const isNativeAvailable =
  Platform.OS === 'ios' &&
  parseInt(Platform.Version as string, 10) >= 16 &&
  UIManager.getViewManagerConfig('NativeBarChart') != null;

// Composant natif SwiftUI
const NativeBarChartView = isNativeAvailable
  ? requireNativeComponent<NativeBarChartProps>('NativeBarChart')
  : null;

interface DataPoint {
  value: number;
  label?: string;
  [key: string]: any;
}

interface NativeBarChartProps {
  data: DataPoint[];
  color: string;
  avgValue?: number;
  chartHeight?: number;
  style?: ViewStyle;
}

interface BarChartWrapperProps {
  data: DataPoint[];
  color?: string;
  height?: number;
  avgValue?: number | null;
  title?: string;
  formatLabel?: (value: number) => string;
  compact?: boolean;
  style?: ViewStyle;
}

const NativeBarChart: React.FC<BarChartWrapperProps> = ({
  data,
  color = colors.sports.running,
  height = 80,
  avgValue = null,
  title,
  formatLabel,
  compact = false,
  style,
}) => {
  const chartData = useMemo(() => {
    return data.filter(point => point.value != null && !isNaN(point.value) && point.value > 0);
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

  const chartHeight = compact ? 60 : height;

  // Utiliser le composant natif SwiftUI si disponible
  if (isNativeAvailable && NativeBarChartView) {
    return (
      <View style={[styles.container, compact && styles.containerCompact, style]}>
        {title && <Text style={styles.title}>{title}</Text>}
        <View style={styles.chartContainer}>
          <NativeBarChartView
            data={chartData}
            color={color}
            avgValue={avgValue || 0}
            chartHeight={chartHeight}
            style={{ width: '100%', height: chartHeight + 20 }}
          />
        </View>
      </View>
    );
  }

  // Calculer la moyenne si non fournie
  const avg = avgValue || chartData.reduce((sum, d) => sum + d.value, 0) / chartData.length;

  // Préparer les données pour react-native-gifted-charts
  const barData = chartData.map((point, index) => {
    // Couleur basée sur la performance
    let barColor = color;
    if (point.value < avg * 0.95) {
      barColor = colors.status.success; // Meilleur que la moyenne
    } else if (point.value > avg * 1.05) {
      barColor = colors.status.error; // Moins bon
    }

    return {
      value: point.value,
      label: point.label || `${index + 1}`,
      frontColor: barColor,
      topLabelComponent: formatLabel
        ? () => <Text style={styles.barTopLabel}>{formatLabel(point.value)}</Text>
        : undefined,
    };
  });

  return (
    <View style={[styles.container, compact && styles.containerCompact, style]}>
      {title && <Text style={styles.title}>{title}</Text>}
      <View style={styles.chartContainer}>
        <BarChart
          data={barData}
          height={chartHeight}
          barWidth={18}
          spacing={8}
          hideRules
          hideYAxisText
          hideAxesAndRules
          xAxisLabelTextStyle={styles.barLabel}
          noOfSections={3}
          isAnimated
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
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 8,
    elevation: 2,
  },
  containerCompact: {
    padding: spacing.sm,
  },
  title: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    marginBottom: spacing.xs,
  },
  chartContainer: {
    alignItems: 'center',
    overflow: 'hidden',
  },
  barLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    fontSize: 10,
  },
  barTopLabel: {
    ...typography.styles.caption,
    color: colors.secondary[800],
    fontSize: 8,
    marginBottom: 2,
  },
  noDataContainer: {
    height: 60,
    justifyContent: 'center',
    alignItems: 'center',
  },
  noDataText: {
    ...typography.styles.body,
    color: colors.neutral.gray[400],
  },
});

export default NativeBarChart;
