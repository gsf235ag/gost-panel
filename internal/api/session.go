package api

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

// getSessions 获取当前用户的活跃会话列表
func (s *Server) getSessions(c *gin.Context) {
	userID, _ := getUserInfo(c)
	currentJTI, _ := c.Get("jti")

	sessions, err := s.svc.GetUserSessions(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// 标记当前会话
	for i := range sessions {
		if jti, ok := currentJTI.(string); ok && sessions[i].TokenJTI == jti {
			sessions[i].IP = sessions[i].IP + " (当前)"
		}
	}

	c.JSON(http.StatusOK, sessions)
}

// deleteSession 撤销指定会话（强制下线）
func (s *Server) deleteSession(c *gin.Context) {
	userID, _ := getUserInfo(c)
	currentJTI, _ := c.Get("jti")
	sessionID, _ := strconv.ParseUint(c.Param("id"), 10, 32)

	// 检查会话是否属于当前用户
	session, err := s.svc.GetSessionByID(uint(sessionID))
	if err != nil || session.UserID != userID {
		c.JSON(http.StatusNotFound, gin.H{"error": "session not found"})
		return
	}

	// 不允许删除当前会话
	if jti, ok := currentJTI.(string); ok && session.TokenJTI == jti {
		c.JSON(http.StatusBadRequest, gin.H{"error": "cannot delete current session"})
		return
	}

	if err := s.svc.DeleteSession(uint(sessionID)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// 记录操作
	username, _ := c.Get("username")
	s.svc.LogOperation(userID, username.(string), "delete", "user_session", uint(sessionID),
		"session revoked", c.ClientIP(), c.GetHeader("User-Agent"), "success")

	c.JSON(http.StatusOK, gin.H{"success": true})
}

// deleteOtherSessions 撤销除当前外所有会话
func (s *Server) deleteOtherSessions(c *gin.Context) {
	userID, _ := getUserInfo(c)
	currentJTI, _ := c.Get("jti")

	jti, ok := currentJTI.(string)
	if !ok || jti == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid session"})
		return
	}

	count, err := s.svc.DeleteOtherSessions(userID, jti)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// 记录操作
	username, _ := c.Get("username")
	s.svc.LogOperation(userID, username.(string), "delete", "user_session", 0,
		"all other sessions revoked", c.ClientIP(), c.GetHeader("User-Agent"), "success")

	c.JSON(http.StatusOK, gin.H{"success": true, "count": count})
}
