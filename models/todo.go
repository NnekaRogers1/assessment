package models

import (
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Todo struct {
	ID     primitive.ObjectID `json:"ID" bson:"_id"`
	UserID string             `json:"userid" bson:"userid"`
	Task   string             `json:"name,omitempty" bson:"task,omitempty"`
	Done   bool               `json:"done,omitempty" bson:"done,omitempty"`
	Status string             `json:"status,omitempty" bson:"status,omitempty"`
}

