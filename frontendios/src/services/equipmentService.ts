/**
 * Service Equipment pour EdgeCoach iOS
 * Gestion de l'équipement sportif (vélos, chaussures, etc.)
 */

import apiService from './api';

// Types
export interface EquipmentItem {
  id: string;
  name: string;
  brand: string;
  model: string;
  year: string;
  notes: string;
  isActive: boolean;
  specifications: Record<string, any>;
}

export interface SportEquipment {
  bikes?: EquipmentItem[];
  shoes?: EquipmentItem[];
  clothes?: EquipmentItem[];
  suits?: EquipmentItem[];
  goggles?: EquipmentItem[];
  accessories?: EquipmentItem[];
}

export interface UserEquipment {
  cycling: SportEquipment;
  running: SportEquipment;
  swimming: SportEquipment;
  totalActiveItems: number;
  createdAt?: string;
  updatedAt?: string;
}

export interface AddEquipmentData {
  sport: 'cycling' | 'running' | 'swimming';
  category: string;
  name: string;
  brand?: string;
  model?: string;
  year?: string;
  notes?: string;
  specifications?: Record<string, any>;
}

export interface UpdateEquipmentData {
  name?: string;
  brand?: string;
  model?: string;
  year?: string;
  notes?: string;
  isActive?: boolean;
  specifications?: Record<string, any>;
}

export interface EquipmentResult {
  success: boolean;
  equipment?: UserEquipment;
  error?: string;
}

export interface EquipmentItemResult {
  success: boolean;
  item?: EquipmentItem;
  message?: string;
  error?: string;
}

class EquipmentService {
  /**
   * Récupérer tout l'équipement d'un utilisateur
   */
  async getEquipment(userId: string): Promise<EquipmentResult> {
    try {
      const timestamp = Date.now();
      const response = await apiService.get<any>(`/users/${userId}/equipment`, { _t: timestamp.toString() });
      const equipment = this.convertApiToFrontend(response);

      return {
        success: true,
        equipment,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Récupérer l'équipement d'un sport spécifique
   */
  async getEquipmentBySport(
    userId: string,
    sport: 'cycling' | 'running' | 'swimming'
  ): Promise<{ success: boolean; equipment?: SportEquipment; sport?: string; error?: string }> {
    try {
      const response = await apiService.get<{ equipment: any; sport: string }>(`/users/${userId}/equipment/${sport}`);

      return {
        success: true,
        equipment: response.equipment,
        sport: response.sport,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Ajouter un équipement
   */
  async addEquipment(userId: string, equipmentData: AddEquipmentData): Promise<EquipmentItemResult> {
    try {
      const apiData: Record<string, any> = {
        sport: equipmentData.sport,
        category: equipmentData.category,
        name: equipmentData.name,
      };

      if (equipmentData.brand) apiData.brand = equipmentData.brand;
      if (equipmentData.model) apiData.model = equipmentData.model;
      if (equipmentData.year) apiData.year = parseInt(equipmentData.year, 10);
      if (equipmentData.notes) apiData.notes = equipmentData.notes;
      if (equipmentData.specifications) apiData.specifications = equipmentData.specifications;

      const response = await apiService.post<{ item: any; message: string }>(`/users/${userId}/equipment`, apiData);

      return {
        success: true,
        item: this.convertItemToFrontend(response.item),
        message: response.message,
      };
    } catch (error: any) {
      let errorMessage = error.message;

      if (error.message.includes('Utilisateur non trouvé') || error.message.includes('404')) {
        errorMessage = 'Utilisateur non trouvé en base de données. Veuillez vous reconnecter.';
      }

      return {
        success: false,
        error: errorMessage,
      };
    }
  }

  /**
   * Mettre à jour un équipement
   */
  async updateEquipment(
    userId: string,
    sport: string,
    category: string,
    itemId: string,
    updateData: UpdateEquipmentData
  ): Promise<{ success: boolean; message?: string; error?: string }> {
    try {
      const apiData: Record<string, any> = {};

      if (updateData.name !== undefined) apiData.name = updateData.name || null;
      if (updateData.brand !== undefined) apiData.brand = updateData.brand || null;
      if (updateData.model !== undefined) apiData.model = updateData.model || null;
      if (updateData.year !== undefined) apiData.year = updateData.year ? parseInt(updateData.year, 10) : null;
      if (updateData.notes !== undefined) apiData.notes = updateData.notes || null;
      if (updateData.isActive !== undefined) apiData.is_active = updateData.isActive;
      if (updateData.specifications !== undefined) apiData.specifications = updateData.specifications || {};

      const response = await apiService.put<{ message: string }>(
        `/users/${userId}/equipment/${sport}/${category}/${itemId}`,
        apiData
      );

      return {
        success: true,
        message: response.message,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Supprimer un équipement
   */
  async deleteEquipment(
    userId: string,
    sport: string,
    category: string,
    itemId: string
  ): Promise<{ success: boolean; message?: string; error?: string }> {
    try {
      const response = await apiService.delete<{ message: string }>(
        `/users/${userId}/equipment/${sport}/${category}/${itemId}`
      );

      return {
        success: true,
        message: response.message,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Dupliquer un équipement
   */
  async duplicateEquipment(
    userId: string,
    originalItem: EquipmentItem,
    sport: 'cycling' | 'running' | 'swimming',
    category: string
  ): Promise<EquipmentItemResult> {
    const duplicatedData: AddEquipmentData = {
      sport,
      category,
      name: `${originalItem.name} (copie)`,
      brand: originalItem.brand || undefined,
      model: originalItem.model || undefined,
      year: originalItem.year || undefined,
      notes: originalItem.notes || undefined,
      specifications: originalItem.specifications || {},
    };

    return this.addEquipment(userId, duplicatedData);
  }

  /**
   * Convertir un item API vers le format frontend
   */
  private convertItemToFrontend(item: any): EquipmentItem {
    return {
      id: item.id,
      name: item.name || '',
      brand: item.brand || '',
      model: item.model || '',
      year: item.year ? item.year.toString() : '',
      notes: item.notes || '',
      isActive: item.is_active !== undefined ? item.is_active : true,
      specifications: item.specifications || {},
    };
  }

  /**
   * Convertir les données API vers le format frontend
   */
  convertApiToFrontend(apiEquipment: any): UserEquipment {
    if (!apiEquipment) {
      return {
        cycling: { bikes: [], shoes: [], accessories: [] },
        running: { shoes: [], clothes: [], accessories: [] },
        swimming: { suits: [], goggles: [], accessories: [] },
        totalActiveItems: 0,
      };
    }

    const convertItems = (items: any[]): EquipmentItem[] => {
      if (!Array.isArray(items)) return [];
      return items.map(item => this.convertItemToFrontend(item));
    };

    return {
      cycling: {
        bikes: convertItems(apiEquipment.cycling?.bikes || []),
        shoes: convertItems(apiEquipment.cycling?.shoes || []),
        accessories: convertItems(apiEquipment.cycling?.accessories || []),
      },
      running: {
        shoes: convertItems(apiEquipment.running?.shoes || []),
        clothes: convertItems(apiEquipment.running?.clothes || []),
        accessories: convertItems(apiEquipment.running?.accessories || []),
      },
      swimming: {
        suits: convertItems(apiEquipment.swimming?.suits || []),
        goggles: convertItems(apiEquipment.swimming?.goggles || []),
        accessories: convertItems(apiEquipment.swimming?.accessories || []),
      },
      totalActiveItems: apiEquipment.total_active_items || 0,
      createdAt: apiEquipment.created_at,
      updatedAt: apiEquipment.updated_at,
    };
  }

  /**
   * Obtenir le nombre total d'équipements par sport
   */
  getEquipmentCount(equipment: UserEquipment, sport?: 'cycling' | 'running' | 'swimming'): number {
    if (!equipment) return 0;

    if (sport && equipment[sport]) {
      return Object.values(equipment[sport]).reduce((total, category) => {
        return total + (Array.isArray(category) ? category.length : 0);
      }, 0);
    }

    let total = 0;
    (['cycling', 'running', 'swimming'] as const).forEach(sportKey => {
      if (equipment[sportKey]) {
        total += Object.values(equipment[sportKey]).reduce((sportTotal, category) => {
          return sportTotal + (Array.isArray(category) ? category.length : 0);
        }, 0);
      }
    });

    return total;
  }

  /**
   * Obtenir les équipements actifs seulement
   */
  getActiveEquipment(equipment: UserEquipment): UserEquipment {
    if (!equipment) {
      return {
        cycling: { bikes: [], shoes: [], accessories: [] },
        running: { shoes: [], clothes: [], accessories: [] },
        swimming: { suits: [], goggles: [], accessories: [] },
        totalActiveItems: 0,
      };
    }

    const filterActive = (items: EquipmentItem[]): EquipmentItem[] => {
      return items.filter(item => item.isActive);
    };

    return {
      cycling: {
        bikes: filterActive(equipment.cycling?.bikes || []),
        shoes: filterActive(equipment.cycling?.shoes || []),
        accessories: filterActive(equipment.cycling?.accessories || []),
      },
      running: {
        shoes: filterActive(equipment.running?.shoes || []),
        clothes: filterActive(equipment.running?.clothes || []),
        accessories: filterActive(equipment.running?.accessories || []),
      },
      swimming: {
        suits: filterActive(equipment.swimming?.suits || []),
        goggles: filterActive(equipment.swimming?.goggles || []),
        accessories: filterActive(equipment.swimming?.accessories || []),
      },
      totalActiveItems: equipment.totalActiveItems,
    };
  }
}

export const equipmentService = new EquipmentService();
export default equipmentService;
