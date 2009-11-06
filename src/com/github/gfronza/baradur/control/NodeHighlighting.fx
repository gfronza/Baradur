/**
 * Copyright (C) 2008 Germano Fronza
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * To contact the author:
 *  - germano.inf@gmail.com
 */
package com.github.gfronza.baradur.control;

import javafx.scene.Group;
import javafx.scene.input.MouseEvent;
import javafx.scene.paint.Color;
import javafx.scene.shape.Rectangle;
import javafx.animation.KeyFrame;
import javafx.animation.Timeline;
import javafx.scene.CustomNode;
import javafx.scene.Node;

/**
 * Implementation of the node highlighting feature.
 * @author germanofronza
 */
public class NodeHighlighting {

    public var highlightingEnabled: Boolean = true;

    protected var registeredNodes: Node[];
    protected var registeredNodesOriginalOnMouseEntered: function(e: MouseEvent)[];
    protected var registeredNodesOriginalOnMouseExited: function(e: MouseEvent)[];

    protected var boundingRects: Rectangle[];

    /**
     * Register a node to provide the highlighting feature.
     * If this node is a Group then register their children nodes.
     */
    public function registerNode(node: Node): Void {
        wrapListener(node);

        if (node instanceof Group) {
            for (n: Node in (node as Group).content) {
                registerNode(n);
            }
        }
        else if (node instanceof CustomNode) {
            registerNode((node as CustomNode).impl_content);
        }
    }

    /**
     * Unregister all nodes, restoring they original callbacks.
     */
    public function unregisterNodes() {
        for (n in registeredNodes) {
            n.onMouseEntered = registeredNodesOriginalOnMouseEntered[indexof n];
            n.onMouseExited = registeredNodesOriginalOnMouseExited[indexof n];
        }

        delete registeredNodes;
        delete registeredNodesOriginalOnMouseEntered;
        delete registeredNodesOriginalOnMouseExited;
    }

    /**
     * Highlight a node programmatically.
     */
    public function highlightNode(node: Node) {
        def boundingBoxRect = getBoundingBoxRectangle(node);
        insert boundingBoxRect into findParentGroup(node.parent).content;
        insert boundingBoxRect into boundingRects;
        
        Timeline {
            keyFrames: [
                KeyFrame {
                    time: .2s
                    action: function() {
                        boundingBoxRect.visible = false;
                    }
                }
                KeyFrame {
                    time: .4s
                    action: function() {
                        boundingBoxRect.visible = true;
                    }
                }
                KeyFrame {
                    time: .6s
                    action: function() {
                        boundingBoxRect.visible = false;
                    }
                }
                KeyFrame {
                    time: .8s
                    action: function() {
                        boundingBoxRect.visible = true;
                    }
                }
                KeyFrame {
                    time: 1s
                    action: function() {
                        delete boundingBoxRect from findParentGroup(node.parent).content;
                        delete boundingBoxRect from boundingRects;
                    }
                }
            ]
        }.play();

    }

    /**
     * Ensure that all boundingbox highlight rectangles are removed from the scene.
     */
    public function ensureBoundingRectsAreRemoved() {
        for (r in boundingRects) {
            delete r from (r.parent as Group).content;
        }
    }

    /**
     * Wrap the onMouseEntered event function to show an opaque rectangle over
     * this node.
     */
    protected function wrapListener(node: Node) {
        var boundingBoxRect : Rectangle;

        var originalMouseEnteredFunction = node.onMouseEntered;
        var originalMouseExitedFunction = node.onMouseExited;

        // store node and it's information to help me unregistering these nodes latter.
        insert node into registeredNodes;
        insert originalMouseEnteredFunction into registeredNodesOriginalOnMouseEntered;
        insert originalMouseExitedFunction into registeredNodesOriginalOnMouseExited;

        // event wrapper.
        node.onMouseEntered = function(e:MouseEvent) : Void {
                
            // triggers the original function
            originalMouseEnteredFunction(e);

            if (highlightingEnabled) {
                boundingBoxRect = getBoundingBoxRectangle(node);

                def parentGroup: Group = findParentGroup(node.parent);
                println(parentGroup);
                insert boundingBoxRect into parentGroup.content;
            }
        };

        node.onMouseExited = function(e:MouseEvent) : Void {
            // triggers the original function
            originalMouseExitedFunction(e);

            if (highlightingEnabled) {
                def parentGroup: Group = findParentGroup(node.parent);
                delete boundingBoxRect from parentGroup.content;
            }
        };
    }

    protected function findParentGroup(node: Node) : Group {
        var group: Group;

        if (node instanceof Group) {
            return node as Group;
        }
        else if (node instanceof CustomNode) {
            return findParentGroup((node as CustomNode).impl_content);
        }
        else {
            if (node.parent != null) {
                return findParentGroup(node.parent);
            }
            return null;
        }
    }

    protected function getBoundingBoxRectangle(node: Node) : Rectangle {
        Rectangle {
            x: node.boundsInParent.minX
            y: node.boundsInParent.minY
            width: node.boundsInParent.width
            height: node.boundsInParent.height
            opacity: 0.25
            fill: Color.BLUE
        };
    }
}
