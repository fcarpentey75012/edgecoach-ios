/**
 * Service Conversation pour EdgeCoach iOS
 * Gestion des conversations (CRUD)
 */

import apiService from './api';

// Types
export interface Message {
  id: string;
  content: string;
  is_ai: boolean;
  message_type: 'text' | 'file' | 'image';
  timestamp: string;
  metadata?: Record<string, any> | null;
}

export interface Conversation {
  id: string;
  conversation_id: string;
  user_id: string;
  title: string;
  messages: Message[];
  created_at: string;
  updated_at: string;
  is_archived: boolean;
  tags: string[];
}

export interface ConversationListItem {
  id: string;
  conversation_id: string;
  title: string;
  message_count: number;
  last_message_preview: string;
  created_at: string;
  updated_at: string;
  is_archived: boolean;
  tags: string[];
}

export interface ConversationStats {
  total_conversations: number;
  active_conversations: number;
  archived_conversations: number;
  total_messages: number;
  average_messages_per_conversation: number;
  most_recent_conversation: string;
}

export interface GetConversationsOptions {
  limit?: number;
  offset?: number;
  includeArchived?: boolean;
}

export interface CreateConversationOptions {
  title?: string;
  initialMessage?: string;
}

export interface UpdateConversationData {
  title?: string;
  messages?: Message[];
  isArchived?: boolean;
  tags?: string[];
}

class ConversationService {
  /**
   * Récupérer la liste des conversations d'un utilisateur
   */
  async getConversations(
    userId: string,
    options: GetConversationsOptions = {}
  ): Promise<ConversationListItem[]> {
    const { limit = 50, offset = 0, includeArchived = false } = options;

    const params = {
      user_id: userId,
      limit: limit.toString(),
      offset: offset.toString(),
      include_archived: includeArchived.toString(),
    };

    return apiService.get<ConversationListItem[]>('/conversations/', params);
  }

  /**
   * Créer une nouvelle conversation
   */
  async createConversation(
    userId: string,
    conversationId: string,
    options: CreateConversationOptions = {}
  ): Promise<Conversation> {
    const { title, initialMessage } = options;

    return apiService.post<Conversation>('/conversations/', {
      user_id: userId,
      conversation_id: conversationId,
      title,
      initial_message: initialMessage,
    });
  }

  /**
   * Récupérer une conversation spécifique
   */
  async getConversation(conversationId: string): Promise<Conversation> {
    return apiService.get<Conversation>(`/conversations/${conversationId}`);
  }

  /**
   * Mettre à jour une conversation
   */
  async updateConversation(
    conversationId: string,
    data: UpdateConversationData
  ): Promise<Conversation> {
    const payload: Record<string, any> = {};

    if (data.title !== undefined) payload.title = data.title;
    if (data.messages !== undefined) payload.messages = data.messages;
    if (data.isArchived !== undefined) payload.is_archived = data.isArchived;
    if (data.tags !== undefined) payload.tags = data.tags;

    return apiService.put<Conversation>(`/conversations/${conversationId}`, payload);
  }

  /**
   * Ajouter un message à une conversation
   */
  async addMessage(
    conversationId: string,
    content: string,
    isAi: boolean,
    options: { messageType?: 'text' | 'file' | 'image'; metadata?: Record<string, any> | null } = {}
  ): Promise<Conversation> {
    const { messageType = 'text', metadata = null } = options;

    return apiService.post<Conversation>(`/conversations/${conversationId}/messages`, {
      content,
      is_ai: isAi,
      message_type: messageType,
      metadata,
    });
  }

  /**
   * Archiver une conversation
   */
  async archiveConversation(conversationId: string): Promise<{ message: string }> {
    return apiService.post<{ message: string }>(`/conversations/${conversationId}/archive`, {});
  }

  /**
   * Supprimer une conversation
   */
  async deleteConversation(conversationId: string): Promise<{ message: string }> {
    return apiService.delete<{ message: string }>(`/conversations/${conversationId}`);
  }

  /**
   * Obtenir les statistiques des conversations
   */
  async getConversationStats(userId: string): Promise<ConversationStats> {
    return apiService.get<ConversationStats>('/conversations/stats', { user_id: userId });
  }

  /**
   * Générer un ID unique pour une nouvelle conversation
   */
  generateConversationId(): string {
    return `conv_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}

export const conversationService = new ConversationService();
export default conversationService;
