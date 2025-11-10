package controller

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/jeffthorne/tasky/auth"
	"github.com/jeffthorne/tasky/database"
	"github.com/jeffthorne/tasky/models"
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

var todoCollection *mongo.Collection = database.OpenCollection(database.Client, "todos")

func GetTodo(c *gin.Context) {
	var ctx, cancel = context.WithTimeout(context.Background(), 100*time.Second)

	id := c.Param("id")
	objId, _ := primitive.ObjectIDFromHex(id)

	var todo models.Todo
	err := todoCollection.FindOne(ctx, bson.M{"_id": objId}).Decode(&todo)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error ": err.Error()})
	}

	defer cancel()
	c.JSON(http.StatusOK, todo)
}

func ClearAll(c *gin.Context) {
	session := auth.ValidateSession(c)
	if !session{
		return
	} 
	
	var ctx, cancel = context.WithTimeout(context.Background(), 100*time.Second)
	userid := c.Param("userid")
	_, err := todoCollection.DeleteMany(ctx, bson.M{"userid": userid})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	defer cancel()
	c.JSON(http.StatusOK, gin.H{"success": "All todos deleted."})

}

func GetTodos(c *gin.Context) {
	session := auth.ValidateSession(c)
	if !session{
		return
	} 
	var ctx, cancel = context.WithTimeout(context.Background(), 100*time.Second)
	userid := c.Param("userid")
	findResult, err := todoCollection.Find(ctx, bson.M{"userid": userid})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"FindError": err.Error()})
		return
	}

	var todos []models.Todo
	for findResult.Next(ctx) {
		var todo models.Todo
		err := findResult.Decode(&todo)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"Decode Error": err.Error()})
			return
		}
		if todo.Status == "" {
			if todo.Done {
				todo.Status = "completed"
			} else {
				todo.Status = "pending"
			}
		}
		todos = append(todos, todo)
	}
	defer cancel()

	c.JSON(http.StatusOK, todos)
}

func DeleteTodo(c *gin.Context) {
	session := auth.ValidateSession(c)
	if !session{
		return
	} 
	var ctx, cancel = context.WithTimeout(context.Background(), 100*time.Second)

	id := c.Param("id")
	userid := c.Param("userid")
	objId, _ := primitive.ObjectIDFromHex(id)
	deleteResult, err := todoCollection.DeleteOne(ctx, bson.M{"_id": objId, "userid": userid})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if deleteResult.DeletedCount == 0 {
		msg := fmt.Sprintf("No todo with id : %v was found, no deletion occurred.", id)
		c.JSON(http.StatusBadRequest, gin.H{"error": msg})
		return
	}
	defer cancel()

	msg := fmt.Sprintf("todo with id : %v was deleted successfully.", id)
	c.JSON(http.StatusOK, gin.H{"success": msg})

}

func UpdateTodo(c *gin.Context) {
	session := auth.ValidateSession(c)
	if !session{
		return
	} 
	var ctx, cancel = context.WithTimeout(context.Background(), 100*time.Second)
	
	var requestData map[string]interface{}
	if err := c.BindJSON(&requestData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	idStr, ok := requestData["ID"].(string)
	if !ok {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID is required"})
		return
	}
	
	objId, err := primitive.ObjectIDFromHex(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID format"})
		return
	}

	userid, ok := requestData["user_id"].(string)
	if !ok {
		c.JSON(http.StatusBadRequest, gin.H{"error": "user_id is required"})
		return
	}

	updateFields := bson.M{}
	if name, ok := requestData["name"].(string); ok {
		updateFields["task"] = name
	}
	if status, ok := requestData["status"].(string); ok {
		updateFields["status"] = status
		updateFields["done"] = (status == "completed")
	}

	_, err = todoCollection.UpdateOne(ctx, bson.M{"_id": objId, "userid": userid}, bson.M{"$set": updateFields})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		fmt.Println(err.Error())
		return
	}

	defer cancel()

	var updatedTodo models.Todo
	err = todoCollection.FindOne(ctx, bson.M{"_id": objId, "userid": userid}).Decode(&updatedTodo)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve updated todo"})
		return
	}

	c.JSON(http.StatusOK, updatedTodo)
}

func AddTodo(c *gin.Context) {
	session := auth.ValidateSession(c)
	if !session{
		return
	} 
	var ctx, cancel = context.WithTimeout(context.Background(), 100*time.Second)

	var requestData map[string]interface{}
	if err := c.BindJSON(&requestData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var todo models.Todo
	todo.ID = primitive.NewObjectID()
	todo.UserID = c.Param("userid")
	
	if name, ok := requestData["name"].(string); ok {
		todo.Task = name
	}
	if status, ok := requestData["status"].(string); ok {
		todo.Status = status
		todo.Done = (status == "completed")
	} else {
		todo.Status = "pending"
		todo.Done = false
	}

	_, err := todoCollection.InsertOne(ctx, todo)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer cancel()
	c.JSON(http.StatusOK, gin.H{"insertedId": todo.ID.Hex()})
}
