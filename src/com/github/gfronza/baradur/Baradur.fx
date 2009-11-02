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
package com.github.gfronza.baradur;

import javafx.scene.Node;
import java.lang.System;
import java.util.logging.Logger;
import com.github.gfronza.baradur.control.NodeHighlighting;
import com.github.gfronza.baradur.view.SceneMonitorViewer;
import javafx.scene.Scene;
import javafx.scene.Group;

/**
 * Singleton instance.
 */
protected var instance: Baradur;

/**
 * Returns the monitor instance.
 * This method is the entry point for Baradur - The greatest watchtower ever!
 */
public function getMonitor() {
    // lazy instantiation.
    if (instance == null) {
        instance = Baradur{};
    }

    return instance;
}

/**
 * Main class of the Baradur JavaFX Scene Monitor Tool.
 * @author germanofronza
 */
public class Baradur {

    /**
     * Reference to the node highlight controller.
     */
    protected var nodeHighlighting;

    /**
     * Reference to the scene monitor viewer.
     */
    protected var sceneMonitorViewer;

    init {
        nodeHighlighting = NodeHighlighting{};
        sceneMonitorViewer = SceneMonitorViewer{
            nodeHighlighting: nodeHighlighting
        };
    }

    /**
     * Shows or hides the Baradur viewer Stage.
     * @param Boolean visible Indicates if should show or hide the viewer.
     */
    public function showViewer(visible: Boolean) {
        sceneMonitorViewer.show(visible);
    }

    /**
     * Register a scene object in the scene monitor.
     * If you want to register a single node, @see registerNode(node: Node, name: String).
     */
    public function registerSceneRootNode(scene: Scene) {
        if (sizeof scene.content > 0) {
            def rootGroup = scene.content[0].parent as Group;
            registerNode(rootGroup, "Scene Root Node");
        }
        else {
            Logger.getLogger(getClass().getName()).info("The scene's content is empty.");
        }
    }

    /**
     * Register a node in the scene monitor.
     * If you want to register all the scene, @see registerSceneRootNode(scene: Scene).
     */
    public function registerNode(node: Node, name: String) {
        def timeAtStart = System.currentTimeMillis();
        Logger.getLogger(getClass().getName()).info("Starting nodes registration...");

        nodeHighlighting.registerNode(node);
        sceneMonitorViewer.registerNode(node, name);

        def totalTime = System.currentTimeMillis() - timeAtStart;
        Logger.getLogger(getClass().getName()).info("Registration finished. Total time: {totalTime} ms.");
    }
}