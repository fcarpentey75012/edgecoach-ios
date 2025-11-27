/**
 * Service utilisateur pour EdgeCoach iOS
 * Gestion de l'authentification et des données utilisateur
 */

import apiService from './api';

// Types
export interface User {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  experience: string;
  phone?: string;
  dateOfBirth?: string;
  gender?: string;
  isActive?: boolean;
  createdAt?: string;
  updatedAt?: string;
}

export interface RegisterData {
  firstName: string;
  lastName: string;
  email: string;
  password: string;
  experienceLevel: string;
}

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface ApiResponse<T> {
  success: boolean;
  user?: T;
  message?: string;
  error?: string;
}

// Interface API (snake_case)
interface ApiUser {
  id?: string;
  _id?: string;
  first_name?: string;
  last_name?: string;
  email?: string;
  experience_level?: string;
  phone?: string;
  date_of_birth?: string;
  gender?: string;
  is_active?: boolean;
  created_at?: string;
  updated_at?: string;
}

class UserService {
  /**
   * Créer un nouveau compte utilisateur
   */
  async register(userData: RegisterData): Promise<ApiResponse<User>> {
    try {
      const response = await apiService.post<{ user: ApiUser; message: string }>(
        '/users/register',
        {
          first_name: userData.firstName,
          last_name: userData.lastName,
          email: userData.email,
          password: userData.password,
          experience_level: userData.experienceLevel,
        }
      );

      return {
        success: true,
        user: this.convertApiToFrontend(response.user),
        message: response.message,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.userMessage || error.message || 'Erreur lors de l\'inscription',
      };
    }
  }

  /**
   * Connexion utilisateur
   */
  async login(credentials: LoginCredentials): Promise<ApiResponse<User>> {
    try {
      const response = await apiService.post<{ user: ApiUser; message: string }>(
        '/users/login',
        {
          email: credentials.email,
          password: credentials.password,
        }
      );

      return {
        success: true,
        user: this.convertApiToFrontend(response.user),
        message: response.message,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.userMessage || error.message || 'Email ou mot de passe incorrect',
      };
    }
  }

  /**
   * Récupérer les informations d'un utilisateur
   */
  async getUserById(userId: string): Promise<ApiResponse<User>> {
    try {
      const response = await apiService.get<ApiUser>(`/users/${userId}`);
      return {
        success: true,
        user: this.convertApiToFrontend(response),
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.userMessage || error.message || 'Utilisateur non trouvé',
      };
    }
  }

  /**
   * Mettre à jour les informations utilisateur
   */
  async updateUser(
    userId: string,
    updateData: Partial<User>
  ): Promise<ApiResponse<User>> {
    try {
      const updatePayload: Record<string, any> = {};

      // Informations de base
      if (updateData.firstName) updatePayload.first_name = updateData.firstName;
      if (updateData.lastName) updatePayload.last_name = updateData.lastName;
      if (updateData.email) updatePayload.email = updateData.email;
      if (updateData.experience) {
        updatePayload.experience_level = updateData.experience;
      }

      // Informations personnelles
      if (updateData.phone !== undefined) updatePayload.phone = updateData.phone;
      if (updateData.dateOfBirth !== undefined) {
        updatePayload.date_of_birth = updateData.dateOfBirth;
      }
      if (updateData.gender !== undefined) updatePayload.gender = updateData.gender;

      if (Object.keys(updatePayload).length === 0) {
        return {
          success: true,
          message: 'Aucune donnée à mettre à jour',
        };
      }

      const response = await apiService.put<{ user: ApiUser; message: string }>(
        `/users/${userId}`,
        updatePayload
      );

      return {
        success: true,
        user: this.convertApiToFrontend(response.user),
        message: response.message,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.userMessage || error.message || 'Erreur lors de la mise à jour',
      };
    }
  }

  /**
   * Convertir les données API vers le format frontend
   */
  convertApiToFrontend(apiUser: ApiUser | null | undefined): User {
    if (!apiUser) {
      return {
        id: '',
        firstName: '',
        lastName: '',
        email: '',
        experience: '',
      };
    }

    return {
      id: apiUser.id || apiUser._id || '',
      firstName: apiUser.first_name || '',
      lastName: apiUser.last_name || '',
      email: apiUser.email || '',
      experience: apiUser.experience_level || '',
      phone: apiUser.phone || '',
      dateOfBirth: apiUser.date_of_birth || '',
      gender: apiUser.gender || '',
      isActive: apiUser.is_active,
      createdAt: apiUser.created_at,
      updatedAt: apiUser.updated_at,
    };
  }
}

export const userService = new UserService();
export default userService;
