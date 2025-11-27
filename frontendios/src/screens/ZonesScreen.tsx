/**
 * Écran des zones d'entraînement
 * Affiche les zones de FC, puissance et allure par sport
 */

import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
  RefreshControl,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { useNavigation } from '@react-navigation/native';
import { useAuth } from '../contexts/AuthContext';
import {
  metricsService,
  UserMetrics,
  HeartRateZone,
  PowerZone,
  PaceZone,
} from '../services/metricsService';
import { colors, spacing, typography } from '../theme';

type Sport = 'running' | 'cycling' | 'swimming';

interface SportOption {
  id: Sport;
  label: string;
  icon: string;
  color: string;
}

const SPORTS: SportOption[] = [
  { id: 'running', label: 'Course', icon: 'walk', color: colors.sports.running },
  { id: 'cycling', label: 'Vélo', icon: 'bicycle', color: colors.sports.cycling },
  { id: 'swimming', label: 'Natation', icon: 'water', color: colors.sports.swimming },
];

const ZonesScreen: React.FC = () => {
  const navigation = useNavigation();
  const { user } = useAuth();

  const [selectedSport, setSelectedSport] = useState<Sport>('running');
  const [metrics, setMetrics] = useState<UserMetrics | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Charger les métriques
  const loadMetrics = useCallback(async (forceRefresh = false) => {
    if (!user?.id) return;

    if (forceRefresh) {
      setIsRefreshing(true);
    } else {
      setIsLoading(true);
    }
    setError(null);

    try {
      const result = await metricsService.getMetrics(user.id, forceRefresh);

      if (result.success && result.metrics) {
        setMetrics(result.metrics);
      } else {
        setError(result.error || 'Erreur lors du chargement des métriques');
      }
    } catch (err) {
      console.error('Error loading metrics:', err);
      setError('Erreur de connexion');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [user?.id]);

  useEffect(() => {
    loadMetrics();
  }, [loadMetrics]);

  // Obtenir les zones du sport sélectionné
  const getCurrentZones = (): (HeartRateZone | PowerZone | PaceZone)[] => {
    if (!metrics) return [];
    return metricsService.getZonesBySport(metrics, selectedSport);
  };

  // Obtenir les informations de référence du sport
  const getRefValue = (): { label: string; value: string } | null => {
    if (!metrics) return null;

    switch (selectedSport) {
      case 'running':
        if (metrics.sportsZones.running) {
          return {
            label: 'FC Seuil',
            value: `${metrics.sportsZones.running.lactateThresholdHr} bpm`,
          };
        }
        break;
      case 'cycling':
        if (metrics.sportsZones.cycling) {
          return {
            label: 'FTP',
            value: `${metrics.sportsZones.cycling.ftp} W`,
          };
        }
        break;
      case 'swimming':
        if (metrics.sportsZones.swimming) {
          return {
            label: 'CSS',
            value: metrics.sportsZones.swimming.cssPace,
          };
        }
        break;
    }
    return null;
  };

  // Rendu d'un sélecteur de sport
  const renderSportSelector = () => (
    <View style={styles.sportSelector}>
      {SPORTS.map((sport) => {
        const isSelected = selectedSport === sport.id;
        const hasData = metrics?.sportsZones?.[sport.id] !== null;

        return (
          <TouchableOpacity
            key={sport.id}
            style={[
              styles.sportButton,
              isSelected && { backgroundColor: sport.color + '20', borderColor: sport.color },
              !hasData && styles.sportButtonDisabled,
            ]}
            onPress={() => hasData && setSelectedSport(sport.id)}
            disabled={!hasData}
          >
            <Icon
              name={sport.icon}
              size={24}
              color={isSelected ? sport.color : hasData ? colors.neutral.gray[500] : colors.neutral.gray[300]}
            />
            <Text
              style={[
                styles.sportButtonText,
                isSelected && { color: sport.color },
                !hasData && styles.sportButtonTextDisabled,
              ]}
            >
              {sport.label}
            </Text>
            {!hasData && (
              <View style={styles.noDataBadge}>
                <Text style={styles.noDataBadgeText}>N/A</Text>
              </View>
            )}
          </TouchableOpacity>
        );
      })}
    </View>
  );

  // Rendu de la valeur de référence
  const renderRefValue = () => {
    const refValue = getRefValue();
    if (!refValue) return null;

    const currentSport = SPORTS.find(s => s.id === selectedSport);

    return (
      <View style={[styles.refValueCard, { borderLeftColor: currentSport?.color }]}>
        <Text style={styles.refValueLabel}>{refValue.label}</Text>
        <Text style={[styles.refValueText, { color: currentSport?.color }]}>{refValue.value}</Text>
      </View>
    );
  };

  // Rendu d'une zone (course)
  const renderRunningZone = (zone: HeartRateZone) => (
    <View key={zone.zone} style={styles.zoneCard}>
      <View style={[styles.zoneIndicator, { backgroundColor: zone.color }]}>
        <Text style={styles.zoneNumber}>Z{zone.zone}</Text>
      </View>
      <View style={styles.zoneContent}>
        <Text style={styles.zoneName}>{zone.name}</Text>
        <View style={styles.zoneValues}>
          <View style={styles.zoneValueItem}>
            <Icon name="heart" size={14} color={colors.status.error} />
            <Text style={styles.zoneValueText}>{zone.min} - {zone.max} bpm</Text>
          </View>
          {zone.pace && (
            <View style={styles.zoneValueItem}>
              <Icon name="speedometer" size={14} color={colors.primary[500]} />
              <Text style={styles.zoneValueText}>{zone.pace}</Text>
            </View>
          )}
        </View>
        <Text style={styles.zoneDescription}>{zone.description}</Text>
      </View>
    </View>
  );

  // Rendu d'une zone (vélo)
  const renderCyclingZone = (zone: PowerZone) => (
    <View key={zone.zone} style={styles.zoneCard}>
      <View style={[styles.zoneIndicator, { backgroundColor: zone.color }]}>
        <Text style={styles.zoneNumber}>Z{zone.zone}</Text>
      </View>
      <View style={styles.zoneContent}>
        <Text style={styles.zoneName}>{zone.name}</Text>
        <View style={styles.zoneValues}>
          <View style={styles.zoneValueItem}>
            <Icon name="flash" size={14} color={colors.status.warning} />
            <Text style={styles.zoneValueText}>{zone.min} - {zone.max} W</Text>
          </View>
          <View style={styles.zoneValueItem}>
            <Icon name="trending-up" size={14} color={colors.primary[500]} />
            <Text style={styles.zoneValueText}>{zone.percentage} FTP</Text>
          </View>
        </View>
        <Text style={styles.zoneDescription}>{zone.description}</Text>
      </View>
    </View>
  );

  // Rendu d'une zone (natation)
  const renderSwimmingZone = (zone: PaceZone) => (
    <View key={zone.zone} style={styles.zoneCard}>
      <View style={[styles.zoneIndicator, { backgroundColor: zone.color }]}>
        <Text style={styles.zoneNumber}>Z{zone.zone}</Text>
      </View>
      <View style={styles.zoneContent}>
        <Text style={styles.zoneName}>{zone.name}</Text>
        <View style={styles.zoneValues}>
          <View style={styles.zoneValueItem}>
            <Icon name="timer" size={14} color={colors.sports.swimming} />
            <Text style={styles.zoneValueText}>{zone.pace} /100m</Text>
          </View>
        </View>
        <Text style={styles.zoneDescription}>{zone.description}</Text>
      </View>
    </View>
  );

  // Rendu des zones
  const renderZones = () => {
    const zones = getCurrentZones();

    if (zones.length === 0) {
      return (
        <View style={styles.emptyContainer}>
          <Icon name="pulse-outline" size={48} color={colors.neutral.gray[300]} />
          <Text style={styles.emptyTitle}>Aucune zone définie</Text>
          <Text style={styles.emptyText}>
            Les zones d'entraînement pour ce sport n'ont pas encore été calculées.
          </Text>
        </View>
      );
    }

    return (
      <View style={styles.zonesContainer}>
        {zones.map((zone) => {
          if (selectedSport === 'running') {
            return renderRunningZone(zone as HeartRateZone);
          } else if (selectedSport === 'cycling') {
            return renderCyclingZone(zone as PowerZone);
          } else {
            return renderSwimmingZone(zone as PaceZone);
          }
        })}
      </View>
    );
  };

  // Affichage pendant le chargement
  if (isLoading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color={colors.primary[500]} />
        <Text style={styles.loadingText}>Chargement des zones...</Text>
      </View>
    );
  }

  // Affichage en cas d'erreur
  if (error) {
    return (
      <View style={styles.errorContainer}>
        <Icon name="alert-circle-outline" size={48} color={colors.status.error} />
        <Text style={styles.errorTitle}>Erreur</Text>
        <Text style={styles.errorText}>{error}</Text>
        <TouchableOpacity style={styles.retryButton} onPress={() => loadMetrics()}>
          <Text style={styles.retryButtonText}>Réessayer</Text>
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()}>
          <Icon name="arrow-back" size={24} color={colors.secondary[800]} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Zones d'entraînement</Text>
        <View style={styles.headerSpacer} />
      </View>

      <ScrollView
        style={styles.scrollContent}
        contentContainerStyle={styles.scrollContentInner}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={() => loadMetrics(true)}
            colors={[colors.primary[500]]}
          />
        }
      >
        {/* Sélecteur de sport */}
        {renderSportSelector()}

        {/* Valeur de référence */}
        {renderRefValue()}

        {/* Liste des zones */}
        {renderZones()}

        {/* Info */}
        <View style={styles.infoCard}>
          <Icon name="information-circle" size={20} color={colors.primary[500]} />
          <Text style={styles.infoText}>
            Les zones sont calculées automatiquement à partir de vos données d'entraînement et tests de terrain.
          </Text>
        </View>
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.light.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingTop: spacing.xl * 2,
    paddingBottom: spacing.md,
    paddingHorizontal: spacing.md,
    backgroundColor: colors.neutral.white,
    borderBottomWidth: 1,
    borderBottomColor: colors.neutral.gray[200],
  },
  backButton: {
    padding: spacing.xs,
  },
  headerTitle: {
    ...typography.styles.h4,
    color: colors.secondary[800],
  },
  headerSpacer: {
    width: 32,
  },
  scrollContent: {
    flex: 1,
  },
  scrollContentInner: {
    padding: spacing.md,
    paddingBottom: spacing.xl * 2,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.light.background,
  },
  loadingText: {
    ...typography.styles.body,
    color: colors.neutral.gray[500],
    marginTop: spacing.md,
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.light.background,
    padding: spacing.xl,
  },
  errorTitle: {
    ...typography.styles.h4,
    color: colors.status.error,
    marginTop: spacing.md,
  },
  errorText: {
    ...typography.styles.body,
    color: colors.neutral.gray[500],
    textAlign: 'center',
    marginTop: spacing.sm,
  },
  retryButton: {
    backgroundColor: colors.primary[500],
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.sm,
    borderRadius: spacing.borderRadius.md,
    marginTop: spacing.lg,
  },
  retryButtonText: {
    ...typography.styles.label,
    color: colors.neutral.white,
  },
  sportSelector: {
    flexDirection: 'row',
    gap: spacing.sm,
    marginBottom: spacing.lg,
  },
  sportButton: {
    flex: 1,
    alignItems: 'center',
    backgroundColor: colors.neutral.white,
    paddingVertical: spacing.md,
    borderRadius: spacing.borderRadius.md,
    borderWidth: 2,
    borderColor: 'transparent',
    gap: spacing.xs,
  },
  sportButtonDisabled: {
    opacity: 0.5,
  },
  sportButtonText: {
    ...typography.styles.caption,
    color: colors.neutral.gray[600],
    fontWeight: '600',
  },
  sportButtonTextDisabled: {
    color: colors.neutral.gray[400],
  },
  noDataBadge: {
    position: 'absolute',
    top: spacing.xs,
    right: spacing.xs,
    backgroundColor: colors.neutral.gray[200],
    paddingHorizontal: spacing.xs,
    paddingVertical: 2,
    borderRadius: spacing.borderRadius.sm,
  },
  noDataBadgeText: {
    ...typography.styles.caption,
    fontSize: 10,
    color: colors.neutral.gray[500],
  },
  refValueCard: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.md,
    padding: spacing.md,
    marginBottom: spacing.lg,
    borderLeftWidth: 4,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  refValueLabel: {
    ...typography.styles.label,
    color: colors.neutral.gray[600],
  },
  refValueText: {
    ...typography.styles.h3,
    fontWeight: '700',
  },
  zonesContainer: {
    gap: spacing.sm,
  },
  zoneCard: {
    flexDirection: 'row',
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.md,
    overflow: 'hidden',
  },
  zoneIndicator: {
    width: 48,
    justifyContent: 'center',
    alignItems: 'center',
  },
  zoneNumber: {
    ...typography.styles.label,
    color: colors.neutral.white,
    fontWeight: '700',
  },
  zoneContent: {
    flex: 1,
    padding: spacing.md,
  },
  zoneName: {
    ...typography.styles.label,
    color: colors.secondary[800],
    marginBottom: spacing.xs,
  },
  zoneValues: {
    flexDirection: 'row',
    gap: spacing.md,
    marginBottom: spacing.xs,
  },
  zoneValueItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  zoneValueText: {
    ...typography.styles.caption,
    color: colors.secondary[600],
  },
  zoneDescription: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  emptyContainer: {
    alignItems: 'center',
    paddingVertical: spacing.xl * 2,
  },
  emptyTitle: {
    ...typography.styles.h4,
    color: colors.neutral.gray[500],
    marginTop: spacing.md,
  },
  emptyText: {
    ...typography.styles.body,
    color: colors.neutral.gray[400],
    textAlign: 'center',
    marginTop: spacing.sm,
    paddingHorizontal: spacing.xl,
  },
  infoCard: {
    flexDirection: 'row',
    backgroundColor: colors.primary[50],
    borderRadius: spacing.borderRadius.md,
    padding: spacing.md,
    marginTop: spacing.lg,
    gap: spacing.sm,
    alignItems: 'flex-start',
  },
  infoText: {
    ...typography.styles.bodySmall,
    color: colors.primary[700],
    flex: 1,
  },
});

export default ZonesScreen;
