/**
 * Composant graphique de répartition par zones
 * Utilise les charts natifs SwiftUI iOS 16+ avec fallback
 * Affiche les zones de puissance/FC sous forme de barres horizontales
 */

import React from 'react';
import NativeZonesChart, {
  NativeZonesChartCompact,
  ZoneData,
} from '../charts/native/NativeZonesChart';

interface ZonesChartProps {
  zones: ZoneData[];
  sportColor: string;
  title?: string;
  showLegend?: boolean;
}

// Re-export du type ZoneData
export type { ZoneData };

const ZonesChart: React.FC<ZonesChartProps> = ({
  zones,
  sportColor,
  title = 'Répartition par zones',
  showLegend = true,
}) => {
  return (
    <NativeZonesChart
      zones={zones}
      sportColor={sportColor}
      title={title}
      showLabels={true}
      showLegend={showLegend}
    />
  );
};

// Re-export de la version compacte
export { NativeZonesChartCompact as ZonesChartCompact };

export default ZonesChart;
