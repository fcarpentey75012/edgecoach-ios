/**
 * Export des composants de graphiques
 */

export { default as ElevationChart } from './ElevationChart';
export { default as PowerChart } from './PowerChart';
export { default as HeartRateChart } from './HeartRateChart';
export { default as PaceChart } from './PaceChart';
export { default as SpeedChart } from './SpeedChart';
export { default as LapsTable } from './LapsTable';

// Graphiques spécifiques running
export {
  PaceGraph,
  CadenceGraph,
  RunningPowerGraph,
  GroundContactTimeGraph,
  VerticalOscillationGraph,
  StrideLengthGraph,
} from './RunningCharts';
