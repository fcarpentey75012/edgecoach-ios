/**
 * Wrapper React Native pour le graphique donut SwiftUI natif
 * Utilisé pour afficher les zones FC en pie chart
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
import { PieChart } from 'react-native-gifted-charts';
import { colors, spacing, typography } from '../../../theme';

// Vérifier si le composant natif est disponible
const isNativeAvailable =
  Platform.OS === 'ios' &&
  parseInt(Platform.Version as string, 10) >= 16 &&
  UIManager.getViewManagerConfig('NativeDonutChart') != null;

// Composant natif SwiftUI
const NativeDonutChartView = isNativeAvailable
  ? requireNativeComponent<NativeDonutChartProps>('NativeDonutChart')
  : null;

export interface ZoneData {
  zone: number;
  time_seconds: number;
  percentage: number;
}

interface NativeDonutChartProps {
  zones: ZoneData[];
  innerRadius?: number;
  outerRadius?: number;
  style?: ViewStyle;
}

interface DonutChartWrapperProps {
  zones: ZoneData[];
  size?: number;
  innerRadius?: number;
  showLegend?: boolean;
  compact?: boolean;
  style?: ViewStyle;
}

// Couleurs des zones
const ZONE_COLORS = [
  '#94a3b8', // Z1
  '#22c55e', // Z2
  '#84cc16', // Z3
  '#eab308', // Z4
  '#f97316', // Z5
  '#ef4444', // Z6
  '#dc2626', // Z7
];

const ZONE_NAMES = ['Récup', 'Z1', 'Z2', 'Z3', 'Z4', 'Z5', 'Z6', 'Z7'];

const NativeDonutChart: React.FC<DonutChartWrapperProps> = ({
  zones,
  size = 90,
  innerRadius = 0.5,
  showLegend = true,
  compact = false,
  style,
}) => {
  const sortedZones = useMemo(() => {
    return zones
      .filter(z => z && typeof z.percentage === 'number' && z.percentage > 0)
      .sort((a, b) => a.zone - b.zone);
  }, [zones]);

  const pieData = useMemo(() => {
    return sortedZones.map(zone => ({
      value: zone.percentage,
      color: ZONE_COLORS[zone.zone] || colors.neutral.gray[400],
      text: ZONE_NAMES[zone.zone] || `Z${zone.zone}`,
    }));
  }, [sortedZones]);

  if (sortedZones.length === 0) {
    return null;
  }

  const chartSize = compact ? 70 : size;
  const innerRatio = compact ? 0.5 : innerRadius;

  // Utiliser le composant natif SwiftUI si disponible
  if (isNativeAvailable && NativeDonutChartView) {
    return (
      <View style={[styles.container, style]}>
        <NativeDonutChartView
          zones={sortedZones}
          innerRadius={innerRatio}
          outerRadius={1.0}
          style={{ width: chartSize, height: chartSize }}
        />
        {showLegend && (
          <View style={styles.legend}>
            {pieData.slice(0, 5).map((zone, index) => (
              <View key={index} style={styles.legendItem}>
                <View style={[styles.legendDot, { backgroundColor: zone.color }]} />
                <Text style={styles.legendText}>{zone.text}</Text>
                <Text style={styles.legendPercent}>{zone.value.toFixed(0)}%</Text>
              </View>
            ))}
          </View>
        )}
      </View>
    );
  }

  // Fallback sur react-native-gifted-charts
  return (
    <View style={[styles.container, style]}>
      <PieChart
        data={pieData}
        radius={chartSize / 2}
        innerRadius={chartSize / 2 * innerRatio}
        showText={false}
      />
      {showLegend && (
        <View style={styles.legend}>
          {pieData.slice(0, 5).map((zone, index) => (
            <View key={index} style={styles.legendItem}>
              <View style={[styles.legendDot, { backgroundColor: zone.color }]} />
              <Text style={styles.legendText}>{zone.text}</Text>
              <Text style={styles.legendPercent}>{zone.value.toFixed(0)}%</Text>
            </View>
          ))}
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.sm,
  },
  legend: {
    gap: 2,
  },
  legendItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  legendDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  legendText: {
    ...typography.styles.caption,
    color: colors.neutral.gray[600],
    fontSize: 10,
  },
  legendPercent: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    fontSize: 10,
  },
});

export default NativeDonutChart;
