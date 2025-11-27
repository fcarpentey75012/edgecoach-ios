/**
 * Wrapper React Native pour le graphique de zones SwiftUI natif
 * Affiche les zones de puissance/FC sous forme de barres horizontales
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
import { colors, spacing, typography } from '../../../theme';

// Vérifier si le composant natif est disponible
const isNativeAvailable =
  Platform.OS === 'ios' &&
  parseInt(Platform.Version as string, 10) >= 16 &&
  UIManager.getViewManagerConfig('NativeZonesChart') != null;

// Composant natif SwiftUI
const NativeZonesChartView = isNativeAvailable
  ? requireNativeComponent<NativeZonesChartProps>('NativeZonesChart')
  : null;

export interface ZoneData {
  zone: number;
  time_seconds: number;
  percentage: number;
}

interface NativeZonesChartProps {
  zones: ZoneData[];
  showLabels?: boolean;
  style?: ViewStyle;
}

interface ZonesChartWrapperProps {
  zones: ZoneData[];
  sportColor?: string;
  title?: string;
  showLabels?: boolean;
  showLegend?: boolean;
  compact?: boolean;
  style?: ViewStyle;
}

// Couleurs des zones (Z1 à Z7)
const ZONE_COLORS = [
  '#94a3b8', // Z1 - Récupération (gris)
  '#22c55e', // Z2 - Endurance (vert)
  '#84cc16', // Z3 - Tempo (vert-jaune)
  '#eab308', // Z4 - Seuil (jaune)
  '#f97316', // Z5 - VO2max (orange)
  '#ef4444', // Z6 - Anaérobie (rouge)
  '#dc2626', // Z7 - Neuromuscular (rouge foncé)
];

const ZONE_NAMES = ['Récup', 'Endurance', 'Tempo', 'Seuil', 'VO2max', 'Anaérobie', 'Neuro'];

// Formater le temps en HH:MM:SS ou MM:SS
const formatTime = (seconds: number): string => {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = seconds % 60;

  if (hours > 0) {
    return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }
  return `${minutes}:${secs.toString().padStart(2, '0')}`;
};

const NativeZonesChart: React.FC<ZonesChartWrapperProps> = ({
  zones,
  sportColor = colors.primary[500],
  title = 'Répartition par zones',
  showLabels = true,
  showLegend = true,
  compact = false,
  style,
}) => {
  const sortedZones = useMemo(() => {
    return [...zones].sort((a, b) => a.zone - b.zone);
  }, [zones]);

  const totalTime = useMemo(() => {
    return zones.reduce((sum, z) => sum + z.time_seconds, 0);
  }, [zones]);

  const maxPercentage = useMemo(() => {
    return Math.max(...zones.map(z => z.percentage), 1);
  }, [zones]);

  if (zones.length === 0) {
    return null;
  }

  // Utiliser le composant natif SwiftUI si disponible
  if (isNativeAvailable && NativeZonesChartView) {
    return (
      <View style={[styles.container, compact && styles.containerCompact, style]}>
        <Text style={styles.title}>{title}</Text>
        <View style={styles.totalTimeContainer}>
          <Text style={styles.totalTimeLabel}>Temps total en zone</Text>
          <Text style={[styles.totalTimeValue, { color: sportColor }]}>
            {formatTime(totalTime)}
          </Text>
        </View>
        <NativeZonesChartView
          zones={sortedZones}
          showLabels={showLabels}
          style={{ width: '100%', height: sortedZones.length * 36 + 16 }}
        />
        {showLegend && !compact && (
          <View style={styles.legend}>
            {ZONE_NAMES.slice(0, 5).map((name, index) => (
              <View key={index} style={styles.legendItem}>
                <View style={[styles.legendDot, { backgroundColor: ZONE_COLORS[index] }]} />
                <Text style={styles.legendText}>{name}</Text>
              </View>
            ))}
          </View>
        )}
      </View>
    );
  }

  // Fallback React Native
  return (
    <View style={[styles.container, compact && styles.containerCompact, style]}>
      <Text style={styles.title}>{title}</Text>
      <View style={styles.totalTimeContainer}>
        <Text style={styles.totalTimeLabel}>Temps total en zone</Text>
        <Text style={[styles.totalTimeValue, { color: sportColor }]}>
          {formatTime(totalTime)}
        </Text>
      </View>
      <View style={styles.barsContainer}>
        {sortedZones.map(zone => {
          const zoneIndex = zone.zone - 1;
          const zoneColor = ZONE_COLORS[zoneIndex] || colors.neutral.gray[400];
          const barWidth = (zone.percentage / maxPercentage) * 100;

          return (
            <View key={zone.zone} style={styles.barRow}>
              <View style={styles.zoneLabel}>
                <View style={[styles.zoneDot, { backgroundColor: zoneColor }]} />
                <Text style={styles.zoneLabelText}>Z{zone.zone}</Text>
              </View>
              <View style={styles.barContainer}>
                <View
                  style={[
                    styles.bar,
                    {
                      width: `${barWidth}%`,
                      backgroundColor: zoneColor,
                    },
                  ]}
                />
              </View>
              <View style={styles.zoneValues}>
                <Text style={styles.zonePercentage}>{zone.percentage.toFixed(0)}%</Text>
                <Text style={styles.zoneTime}>{formatTime(zone.time_seconds)}</Text>
              </View>
            </View>
          );
        })}
      </View>
      {showLegend && !compact && (
        <View style={styles.legend}>
          {ZONE_NAMES.slice(0, 5).map((name, index) => (
            <View key={index} style={styles.legendItem}>
              <View style={[styles.legendDot, { backgroundColor: ZONE_COLORS[index] }]} />
              <Text style={styles.legendText}>{name}</Text>
            </View>
          ))}
        </View>
      )}
    </View>
  );
};

// Version compacte pour le calendrier/liste
export const NativeZonesChartCompact: React.FC<{
  zones: ZoneData[];
}> = ({ zones }) => {
  const totalTime = zones.reduce((sum, z) => sum + z.time_seconds, 0);
  if (totalTime === 0) return null;

  const sortedZones = [...zones].sort((a, b) => a.zone - b.zone);

  return (
    <View style={stylesCompact.container}>
      <View style={stylesCompact.barContainer}>
        {sortedZones.map(zone => {
          const zoneIndex = zone.zone - 1;
          const zoneColor = ZONE_COLORS[zoneIndex] || colors.neutral.gray[400];

          return (
            <View
              key={zone.zone}
              style={[
                stylesCompact.segment,
                {
                  flex: zone.percentage,
                  backgroundColor: zoneColor,
                },
              ]}
            />
          );
        })}
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
    ...typography.styles.label,
    color: colors.secondary[800],
    fontWeight: '600',
    marginBottom: spacing.sm,
  },
  totalTimeContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.md,
    paddingBottom: spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: colors.neutral.gray[100],
  },
  totalTimeLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  totalTimeValue: {
    ...typography.styles.h4,
    fontWeight: '700',
  },
  barsContainer: {
    gap: spacing.sm,
  },
  barRow: {
    flexDirection: 'row',
    alignItems: 'center',
    height: 28,
  },
  zoneLabel: {
    width: 50,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  zoneDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  zoneLabelText: {
    ...typography.styles.caption,
    color: colors.secondary[700],
    fontWeight: '600',
  },
  barContainer: {
    flex: 1,
    height: 20,
    backgroundColor: colors.neutral.gray[100],
    borderRadius: spacing.borderRadius.sm,
    overflow: 'hidden',
    marginHorizontal: spacing.sm,
  },
  bar: {
    height: '100%',
    borderRadius: spacing.borderRadius.sm,
  },
  zoneValues: {
    width: 70,
    alignItems: 'flex-end',
  },
  zonePercentage: {
    ...typography.styles.caption,
    color: colors.secondary[800],
    fontWeight: '600',
  },
  zoneTime: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    fontSize: 10,
  },
  legend: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginTop: spacing.md,
    paddingTop: spacing.sm,
    borderTopWidth: 1,
    borderTopColor: colors.neutral.gray[100],
    gap: spacing.sm,
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
});

const stylesCompact = StyleSheet.create({
  container: {
    marginTop: spacing.xs,
  },
  barContainer: {
    flexDirection: 'row',
    height: 6,
    borderRadius: 3,
    overflow: 'hidden',
    backgroundColor: colors.neutral.gray[100],
  },
  segment: {
    height: '100%',
  },
});

export default NativeZonesChart;
