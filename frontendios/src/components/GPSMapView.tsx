/**
 * Composant GPSMapView
 * Affiche un tracé GPS sur une carte Apple Maps
 * Inspiré de OptimizedLeafletMap.jsx du frontend web
 */

import React, { useMemo } from 'react';
import { View, Text, StyleSheet, ActivityIndicator } from 'react-native';
import MapView, { Polyline, Marker, PROVIDER_DEFAULT } from 'react-native-maps';
import Icon from 'react-native-vector-icons/Ionicons';
import { colors, spacing, typography } from '../theme';

// Type pour un point GPS (supporte plusieurs formats: FIT, TCX, etc.)
export interface GPSPoint {
  // Format Garmin FIT (semicircles)
  position_lat?: number;
  position_long?: number;
  // Format TCX ou standard (degrés décimaux)
  lat?: number;
  lng?: number;
  latitude?: number;
  longitude?: number;
  // Format alternatif (lon au lieu de lng)
  lon?: number;
  // Métriques
  enhanced_speed?: number;
  speed?: number;
  enhanced_altitude?: number;
  altitude?: number;
  heart_rate?: number;
  hr?: number;
  power?: number;
  distance?: number;
  timestamp?: string;
}

// Type pour les coordonnées converties
interface ConvertedPoint {
  latitude: number;
  longitude: number;
  speed?: number;
  altitude?: number;
  heartRate?: number;
  power?: number;
}

interface GPSMapViewProps {
  recordData?: GPSPoint[];
  sportColor?: string;
  height?: number;
  showMarkers?: boolean;
  isLoading?: boolean;
}

// Conversion des semicircles Garmin vers degrés décimaux
const semicirclesToDegrees = (semicircles: number): number => {
  return semicircles * (180 / Math.pow(2, 31));
};

// Décimation des points GPS pour optimiser les performances
const decimateGPSData = (data: ConvertedPoint[], maxPoints: number = 400): ConvertedPoint[] => {
  if (!data || data.length <= maxPoints) {
    return data;
  }

  const result: ConvertedPoint[] = [];
  const step = (data.length - 2) / (maxPoints - 2);

  // Toujours garder le premier point
  result.push(data[0]);

  // Garder les points intermédiaires
  for (let i = 1; i < maxPoints - 1; i++) {
    const index = Math.round(i * step);
    if (index < data.length - 1) {
      result.push(data[index]);
    }
  }

  // Toujours garder le dernier point
  result.push(data[data.length - 1]);

  return result;
};

const GPSMapView: React.FC<GPSMapViewProps> = ({
  recordData,
  sportColor = colors.primary[500],
  height = 250,
  showMarkers = true,
  isLoading = false,
}) => {
  // Convertir les données GPS
  const gpsData = useMemo(() => {
    if (!recordData || recordData.length === 0) {
      return [];
    }

    // Debug: voir les clés du premier enregistrement
    console.log('GPSMapView: First record keys:', Object.keys(recordData[0]));
    console.log('GPSMapView: First record sample:', recordData[0]);

    const converted = recordData
      .filter(record => {
        // Support pour différents formats (FIT: position_lat/long, TCX: lat/lng ou latitude/longitude)
        const hasGarminCoords = record.position_lat != null && record.position_long != null;
        const hasStandardCoords = record.lat != null && (record.lng != null || record.lon != null);
        const hasFullCoords = record.latitude != null && record.longitude != null;
        return hasGarminCoords || hasStandardCoords || hasFullCoords;
      })
      .map(record => {
        // Extraire les coordonnées selon le format
        let lat: number;
        let lng: number;

        if (record.position_lat != null && record.position_long != null) {
          // Format Garmin FIT (semicircles)
          lat = semicirclesToDegrees(record.position_lat);
          lng = semicirclesToDegrees(record.position_long);
        } else if (record.lat != null && (record.lng != null || record.lon != null)) {
          // Format TCX ou déjà converti (degrés décimaux)
          lat = record.lat;
          lng = record.lng ?? record.lon!;
        } else if (record.latitude != null && record.longitude != null) {
          // Format standard
          lat = record.latitude;
          lng = record.longitude;
        } else {
          return null;
        }

        return {
          latitude: lat,
          longitude: lng,
          speed: record.enhanced_speed ? record.enhanced_speed * 3.6 : record.speed,
          altitude: record.enhanced_altitude || record.altitude,
          heartRate: record.heart_rate || record.hr,
          power: record.power,
        };
      })
      .filter((point): point is NonNullable<typeof point> => point !== null) as ConvertedPoint[];

    console.log('GPSMapView: Converted points count:', converted.length);
    if (converted.length > 0) {
      console.log('GPSMapView: First converted point:', converted[0]);
    }

    // Décimer pour les performances
    return decimateGPSData(converted, 400);
  }, [recordData]);

  // Calculer la région de la carte
  const mapRegion = useMemo(() => {
    if (gpsData.length === 0) {
      return null;
    }

    const lats = gpsData.map(p => p.latitude);
    const lngs = gpsData.map(p => p.longitude);

    const minLat = Math.min(...lats);
    const maxLat = Math.max(...lats);
    const minLng = Math.min(...lngs);
    const maxLng = Math.max(...lngs);

    const centerLat = (minLat + maxLat) / 2;
    const centerLng = (minLng + maxLng) / 2;

    // Ajouter une marge de 20%
    const latDelta = (maxLat - minLat) * 1.2 || 0.01;
    const lngDelta = (maxLng - minLng) * 1.2 || 0.01;

    return {
      latitude: centerLat,
      longitude: centerLng,
      latitudeDelta: Math.max(latDelta, 0.005),
      longitudeDelta: Math.max(lngDelta, 0.005),
    };
  }, [gpsData]);

  // Points de départ et d'arrivée
  const startPoint = gpsData.length > 0 ? gpsData[0] : null;
  const endPoint = gpsData.length > 1 ? gpsData[gpsData.length - 1] : null;

  // Coordonnées pour la polyline
  const polylineCoords = useMemo(() => {
    return gpsData.map(point => ({
      latitude: point.latitude,
      longitude: point.longitude,
    }));
  }, [gpsData]);

  // État de chargement
  if (isLoading) {
    return (
      <View style={[styles.container, { height }]}>
        <ActivityIndicator size="large" color={sportColor} />
        <Text style={styles.loadingText}>Chargement du tracé GPS...</Text>
      </View>
    );
  }

  // Pas de données GPS
  if (!recordData || recordData.length === 0 || gpsData.length === 0) {
    return (
      <View style={[styles.emptyContainer, { height }]}>
        <Icon name="map-outline" size={48} color={colors.neutral.gray[300]} />
        <Text style={styles.emptyTitle}>Aucun tracé GPS</Text>
        <Text style={styles.emptyText}>
          Les coordonnées GPS ne sont pas disponibles pour cette séance.
        </Text>
      </View>
    );
  }

  return (
    <View style={[styles.mapContainer, { height }]}>
      <MapView
        style={styles.map}
        provider={PROVIDER_DEFAULT}
        initialRegion={mapRegion || undefined}
        showsUserLocation={false}
        showsCompass={true}
        showsScale={true}
        mapType="standard"
      >
        {/* Tracé GPS */}
        <Polyline
          coordinates={polylineCoords}
          strokeColor={sportColor}
          strokeWidth={3}
          lineCap="round"
          lineJoin="round"
        />

        {/* Marqueur de départ */}
        {showMarkers && startPoint && (
          <Marker
            coordinate={{
              latitude: startPoint.latitude,
              longitude: startPoint.longitude,
            }}
            title="Départ"
            anchor={{ x: 0.5, y: 1 }}
          >
            <View style={[styles.markerContainer, styles.startMarker]}>
              <Icon name="flag" size={16} color={colors.neutral.white} />
            </View>
          </Marker>
        )}

        {/* Marqueur d'arrivée */}
        {showMarkers && endPoint && (
          <Marker
            coordinate={{
              latitude: endPoint.latitude,
              longitude: endPoint.longitude,
            }}
            title="Arrivée"
            anchor={{ x: 0.5, y: 1 }}
          >
            <View style={[styles.markerContainer, styles.endMarker]}>
              <Icon name="checkmark" size={16} color={colors.neutral.white} />
            </View>
          </Marker>
        )}
      </MapView>

      {/* Légende */}
      <View style={styles.legend}>
        <View style={styles.legendItem}>
          <View style={[styles.legendDot, { backgroundColor: colors.sports.running }]} />
          <Text style={styles.legendText}>Départ</Text>
        </View>
        <View style={styles.legendItem}>
          <View style={[styles.legendDot, { backgroundColor: colors.status.error }]} />
          <Text style={styles.legendText}>Arrivée</Text>
        </View>
      </View>

      {/* Info points */}
      <View style={styles.pointsInfo}>
        <Text style={styles.pointsText}>{gpsData.length} points GPS</Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.neutral.gray[100],
    borderRadius: spacing.borderRadius.md,
  },
  loadingText: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    marginTop: spacing.sm,
  },
  emptyContainer: {
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.neutral.gray[50],
    borderRadius: spacing.borderRadius.md,
    padding: spacing.lg,
  },
  emptyTitle: {
    ...typography.styles.label,
    color: colors.neutral.gray[500],
    marginTop: spacing.sm,
  },
  emptyText: {
    ...typography.styles.caption,
    color: colors.neutral.gray[400],
    textAlign: 'center',
    marginTop: spacing.xs,
  },
  mapContainer: {
    borderRadius: spacing.borderRadius.md,
    overflow: 'hidden',
    backgroundColor: colors.neutral.gray[100],
  },
  map: {
    flex: 1,
  },
  markerContainer: {
    width: 28,
    height: 28,
    borderRadius: 14,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 2,
    borderColor: colors.neutral.white,
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 4,
    elevation: 4,
  },
  startMarker: {
    backgroundColor: colors.sports.running,
  },
  endMarker: {
    backgroundColor: colors.status.error,
  },
  legend: {
    position: 'absolute',
    top: spacing.sm,
    right: spacing.sm,
    backgroundColor: 'rgba(255,255,255,0.9)',
    borderRadius: spacing.borderRadius.sm,
    padding: spacing.xs,
    flexDirection: 'row',
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
  pointsInfo: {
    position: 'absolute',
    bottom: spacing.sm,
    left: spacing.sm,
    backgroundColor: 'rgba(255,255,255,0.9)',
    borderRadius: spacing.borderRadius.sm,
    paddingHorizontal: spacing.xs,
    paddingVertical: 2,
  },
  pointsText: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    fontSize: 10,
  },
});

export default GPSMapView;
