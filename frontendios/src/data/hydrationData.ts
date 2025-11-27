/**
 * Données pour l'hydratation dans le carnet d'entraînement
 */

export interface HydrationOption {
  id: string;
  name: string;
  volume: number;
  icon: string;
}

export interface HydrationContentType {
  id: string;
  name: string;
  color: string;
}

export const hydrationOptions: HydrationOption[] = [
  {
    id: 'bidon-500',
    name: 'Bidon 500ml',
    volume: 500,
    icon: 'water',
  },
  {
    id: 'bidon-750',
    name: 'Bidon 750ml',
    volume: 750,
    icon: 'water',
  },
  {
    id: 'gourde-1000',
    name: 'Gourde 1L',
    volume: 1000,
    icon: 'water',
  },
];

export const hydrationContentTypes: HydrationContentType[] = [
  {
    id: 'water',
    name: 'Eau',
    color: '#3B82F6',
  },
  {
    id: 'electrolytes',
    name: 'Électrolytes',
    color: '#10B981',
  },
  {
    id: 'isotonic',
    name: 'Boisson isotonique',
    color: '#F59E0B',
  },
  {
    id: 'energy',
    name: 'Boisson énergétique',
    color: '#EF4444',
  },
  {
    id: 'bcaa',
    name: 'BCAA',
    color: '#8B5CF6',
  },
];

export const getHydrationOptionById = (id: string): HydrationOption | undefined => {
  return hydrationOptions.find(option => option.id === id);
};

export const getContentTypeById = (id: string): HydrationContentType | undefined => {
  return hydrationContentTypes.find(type => type.id === id);
};
