/**
 * Hook pour gérer le layout personnalisable du dashboard
 * Stocke les préférences de l'utilisateur dans AsyncStorage
 */

import { useState, useEffect, useCallback } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { WidgetConfig, WidgetType } from '../components/dashboard/DashboardWidget';

const STORAGE_KEY = '@edgecoach_dashboard_layout';

// Configuration par défaut des widgets
const DEFAULT_WIDGETS: WidgetConfig[] = [
  {
    id: 'weekly-summary',
    type: 'weekly-summary',
    title: 'Résumé semaine',
    size: 'full',
    visible: true,
    order: 0,
  },
  {
    id: 'weekly-chart',
    type: 'weekly-chart',
    title: 'Volume 7 jours',
    size: 'full',
    visible: true,
    order: 1,
  },
  {
    id: 'sport-cards',
    type: 'sport-cards',
    title: 'Séances par sport',
    size: 'full',
    visible: true,
    order: 2,
  },
  {
    id: 'sport-distribution',
    type: 'sport-distribution',
    title: 'Répartition',
    size: 'full',
    visible: true,
    order: 3,
  },
  {
    id: 'upcoming-sessions',
    type: 'upcoming-sessions',
    title: 'Prochaines séances',
    size: 'full',
    visible: true,
    order: 4,
  },
  {
    id: 'coach-insight',
    type: 'coach-insight',
    title: 'Coach IA',
    size: 'full',
    visible: true,
    order: 5,
  },
];

interface UseDashboardLayoutReturn {
  widgets: WidgetConfig[];
  isEditMode: boolean;
  isLoading: boolean;
  toggleEditMode: () => void;
  toggleWidgetVisibility: (widgetId: string) => void;
  moveWidgetUp: (widgetId: string) => void;
  moveWidgetDown: (widgetId: string) => void;
  resetToDefault: () => void;
  getWidgetConfig: (type: WidgetType) => WidgetConfig | undefined;
}

export const useDashboardLayout = (): UseDashboardLayoutReturn => {
  const [widgets, setWidgets] = useState<WidgetConfig[]>(DEFAULT_WIDGETS);
  const [isEditMode, setIsEditMode] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  // Charger les préférences au montage
  useEffect(() => {
    loadLayoutPreferences();
  }, []);

  // Sauvegarder les préférences quand elles changent
  useEffect(() => {
    if (!isLoading) {
      saveLayoutPreferences();
    }
  }, [widgets]);

  const loadLayoutPreferences = async () => {
    try {
      const stored = await AsyncStorage.getItem(STORAGE_KEY);
      if (stored) {
        const parsed = JSON.parse(stored) as WidgetConfig[];
        // Fusionner avec les défauts pour s'assurer que tous les widgets existent
        const merged = DEFAULT_WIDGETS.map(defaultWidget => {
          const storedWidget = parsed.find(w => w.id === defaultWidget.id);
          return storedWidget || defaultWidget;
        });
        setWidgets(merged.sort((a, b) => a.order - b.order));
      }
    } catch (error) {
      console.error('Erreur chargement layout dashboard:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const saveLayoutPreferences = async () => {
    try {
      await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(widgets));
    } catch (error) {
      console.error('Erreur sauvegarde layout dashboard:', error);
    }
  };

  const toggleEditMode = useCallback(() => {
    setIsEditMode(prev => !prev);
  }, []);

  const toggleWidgetVisibility = useCallback((widgetId: string) => {
    setWidgets(prev =>
      prev.map(widget =>
        widget.id === widgetId ? { ...widget, visible: !widget.visible } : widget
      )
    );
  }, []);

  const moveWidgetUp = useCallback((widgetId: string) => {
    setWidgets(prev => {
      const index = prev.findIndex(w => w.id === widgetId);
      if (index <= 0) return prev;

      const newWidgets = [...prev];
      // Échanger les ordres
      const currentOrder = newWidgets[index].order;
      newWidgets[index].order = newWidgets[index - 1].order;
      newWidgets[index - 1].order = currentOrder;

      return newWidgets.sort((a, b) => a.order - b.order);
    });
  }, []);

  const moveWidgetDown = useCallback((widgetId: string) => {
    setWidgets(prev => {
      const index = prev.findIndex(w => w.id === widgetId);
      if (index === -1 || index >= prev.length - 1) return prev;

      const newWidgets = [...prev];
      // Échanger les ordres
      const currentOrder = newWidgets[index].order;
      newWidgets[index].order = newWidgets[index + 1].order;
      newWidgets[index + 1].order = currentOrder;

      return newWidgets.sort((a, b) => a.order - b.order);
    });
  }, []);

  const resetToDefault = useCallback(async () => {
    setWidgets(DEFAULT_WIDGETS);
    try {
      await AsyncStorage.removeItem(STORAGE_KEY);
    } catch (error) {
      console.error('Erreur reset layout:', error);
    }
  }, []);

  const getWidgetConfig = useCallback(
    (type: WidgetType) => {
      return widgets.find(w => w.type === type);
    },
    [widgets]
  );

  return {
    widgets,
    isEditMode,
    isLoading,
    toggleEditMode,
    toggleWidgetVisibility,
    moveWidgetUp,
    moveWidgetDown,
    resetToDefault,
    getWidgetConfig,
  };
};

export default useDashboardLayout;
