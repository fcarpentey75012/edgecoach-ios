/**
 * Données des gels énergétiques pour le carnet d'entraînement
 */

import { ImageSourcePropType } from 'react-native';

// Import statique des images des gels
// Pour ajouter les vraies images, remplacer les fichiers dans src/assets/images/gels/
const gelImages = {
  'precision-fuel-pf30': require('../assets/images/gels/precision_fuel_pf30.png'),
  'precision-fuel-pf30-cafeine': require('../assets/images/gels/precision_fuel_pf30_caf.png'),
  'gu-energy-original': require('../assets/images/gels/gu_energy.png'),
  'gu-roctane': require('../assets/images/gels/gu_roctane.png'),
  'maurten-gel-100': require('../assets/images/gels/maurten_100.png'),
  'maurten-gel-100-caf': require('../assets/images/gels/maurten_100_caf.png'),
  'science-in-sport-go': require('../assets/images/gels/sis_go.png'),
  'science-in-sport-go-caf': require('../assets/images/gels/sis_go_caf.png'),
  'clif-shot': require('../assets/images/gels/clif_shot.png'),
  'high5-energy': require('../assets/images/gels/high5_energy.png'),
  'high5-energy-caf': require('../assets/images/gels/high5_energy_caf.png'),
  'powerbar-powergel': require('../assets/images/gels/powerbar_powergel.png'),
} as const;

export interface Gel {
  id: string;
  name: string;
  brand: string;
  calories: number;
  carbs: number;
  caffeine: number;
  color: string;
  image?: ImageSourcePropType;
}

export const gelsData: Gel[] = [
  {
    id: 'precision-fuel-pf30',
    name: 'PF 30',
    brand: 'Precision Fuel',
    calories: 120,
    carbs: 30,
    caffeine: 0,
    color: '#4A90E2',
    image: gelImages['precision-fuel-pf30'],
  },
  {
    id: 'precision-fuel-pf30-cafeine',
    name: 'PF 30 Caféine',
    brand: 'Precision Fuel',
    calories: 120,
    carbs: 30,
    caffeine: 100,
    color: '#E94B3C',
    image: gelImages['precision-fuel-pf30-cafeine'],
  },
  {
    id: 'gu-energy-original',
    name: 'Energy Gel',
    brand: 'GU',
    calories: 100,
    carbs: 22,
    caffeine: 20,
    color: '#00A86B',
    image: gelImages['gu-energy-original'],
  },
  {
    id: 'gu-roctane',
    name: 'Roctane',
    brand: 'GU',
    calories: 100,
    carbs: 21,
    caffeine: 35,
    color: '#FF6B35',
    image: gelImages['gu-roctane'],
  },
  {
    id: 'maurten-gel-100',
    name: 'Gel 100',
    brand: 'Maurten',
    calories: 100,
    carbs: 25,
    caffeine: 0,
    color: '#1A1A1A',
    image: gelImages['maurten-gel-100'],
  },
  {
    id: 'maurten-gel-100-caf',
    name: 'Gel 100 CAF',
    brand: 'Maurten',
    calories: 100,
    carbs: 25,
    caffeine: 100,
    color: '#8B4513',
    image: gelImages['maurten-gel-100-caf'],
  },
  {
    id: 'science-in-sport-go',
    name: 'GO Isotonic',
    brand: 'SiS',
    calories: 87,
    carbs: 22,
    caffeine: 0,
    color: '#0066CC',
    image: gelImages['science-in-sport-go'],
  },
  {
    id: 'science-in-sport-go-caf',
    name: 'GO + Caffeine',
    brand: 'SiS',
    calories: 87,
    carbs: 22,
    caffeine: 75,
    color: '#CC0066',
    image: gelImages['science-in-sport-go-caf'],
  },
  {
    id: 'clif-shot',
    name: 'Shot',
    brand: 'Clif',
    calories: 100,
    carbs: 24,
    caffeine: 0,
    color: '#228B22',
    image: gelImages['clif-shot'],
  },
  {
    id: 'high5-energy',
    name: 'Energy Gel',
    brand: 'HIGH5',
    calories: 92,
    carbs: 23,
    caffeine: 0,
    color: '#FFD700',
    image: gelImages['high5-energy'],
  },
  {
    id: 'high5-energy-caf',
    name: 'Energy Gel Caffeine',
    brand: 'HIGH5',
    calories: 92,
    carbs: 23,
    caffeine: 30,
    color: '#FF4500',
    image: gelImages['high5-energy-caf'],
  },
  {
    id: 'powerbar-powergel',
    name: 'PowerGel',
    brand: 'PowerBar',
    calories: 110,
    carbs: 27,
    caffeine: 0,
    color: '#4169E1',
    image: gelImages['powerbar-powergel'],
  },
];

export const getGelById = (id: string): Gel | undefined => {
  return gelsData.find(gel => gel.id === id);
};
