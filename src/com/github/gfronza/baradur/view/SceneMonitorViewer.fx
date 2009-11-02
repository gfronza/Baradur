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
package com.github.gfronza.baradur.view;

import javafx.scene.Node;
import javafx.stage.Stage;
import javafx.scene.Scene;
import javafx.scene.layout.VBox;
import javafx.ext.swing.SwingComboBoxItem;
import javax.swing.JTree;
import javafx.ext.swing.SwingComponent;
import javafx.ext.swing.SwingComboBox;
import javafx.scene.control.Button;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.layout.HBox;
import javax.swing.tree.DefaultMutableTreeNode;
import javafx.util.Sequences;
import javafx.scene.Group;
import com.acarter.propertytable.PropertyTable;
import com.acarter.propertytable.PropertyTableModel;
import java.lang.Boolean;
import java.lang.String;
import javax.swing.BoxLayout;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.tree.DefaultTreeModel;
import javax.swing.event.TreeSelectionListener;
import javax.swing.event.TreeSelectionEvent;
import com.github.gfronza.baradur.control.NodeHighlighting;
import com.github.gfronza.baradur.view.NodeViewRepresentation;
import javafx.ext.swing.SwingScrollPane;
import com.acarter.propertytable.PropertySection;
import com.acarter.propertytable.PropertySectionState;
import java.lang.Class;
import javafx.reflect.FXClassType;
import javafx.reflect.FXContext;
import java.lang.NoSuchMethodException;
import java.lang.reflect.Method;
import com.acarter.propertytable.Property;
import javafx.stage.Alert;


/**
 * This JavaFX class represents the viewer of the Baradur Tool.
 * This viewer shows a Stage with the scene graph visualization based on the
 * registered nodes.
 * @author germanofronza
 */
public class SceneMonitorViewer {

    public-init var nodeHighlighting: NodeHighlighting;

    /**
     * All nodes registered in the tool.
     */
    protected var registeredNodes : Node[];
    protected var registeredNodesName : String[];

    protected var stage: Stage;
    protected def treeNodes = new JTree();
    protected var registeredNodesComboBox: SwingComboBox;

    protected var table : PropertyTable;
    protected var model : PropertyTableModel;

    protected def FXBASE_CLASSNAME = "com.sun.javafx.runtime.FXBase";

    init {
        stage = Stage {
            title: "Baradur - JavaFX Scene Monitor"
            x: 0
            y: 0
            width: 350
            height: 700
            visible: false
            scene: Scene {
                content: [
                    VBox {
                        spacing: 2
                        content: [
                            HBox {
                                spacing: 2
                                content: [
                                    registeredNodesComboBox = SwingComboBox {
                                        width: bind stage.width -47
                                        items: bind getComboBoxItems(registeredNodes)
                                    },
                                    Button {
                                        width: 20
                                        graphic: ImageView {
                                            image: Image {
                                                url: "{__DIR__}lookup.png"
                                            }

                                        }
                                        action: updateSceneGraphAction
                                    }

                                ]
                            }
                            createTreeNodes(),
                            createPanelProperties()
                        ]
                    }
                ]
            }
        }

        addTreeNodesSelectionListener();
    }

    /**
     * Shows the viewer of Baradur Tool.
     */
    public function show(visible: Boolean) {
        if (stage.visible = visible) {
            updateSceneGraphAction();
        }
    }

    /**
     * Register the nodes in the viewer.
     */
    public function registerNode(node: Node, name: String) {
        insert "{name} ({node.getClass().getSimpleName()})" into registeredNodesName;
        insert node into registeredNodes;
    }

    protected function addTreeNodesSelectionListener() {
        //def renderer: DefaultTreeCellRenderer = treeNodes.getCellRenderer() as DefaultTreeCellRenderer;
        treeNodes.addTreeSelectionListener(
            TreeSelectionListener {
                override public function valueChanged(e: TreeSelectionEvent) : Void {
                    def selectedObj = (e.getPath().getLastPathComponent() as DefaultMutableTreeNode).getUserObject();
                    def selectedNode : Node = (selectedObj as NodeViewRepresentation).node;
                    nodeHighlighting.highlightNode(selectedNode);
                    populateNodeProperties(selectedNode);
                }
            }
        );
    }

    protected function populateNodeProperties(node: Node) {
        def sCount = model.getPropertSectionCount();
        for (i in [0..sCount-1]) {
            def s = model.getPropertySection(0);
            model.removePropertySection(s);
        }

        var fxClass = FXContext.getInstance().findClass(node.getClass().getCanonicalName());
        addPropertySession(node, fxClass, node.getClass().getSimpleName());

        var c: Class = node.getClass().getSuperclass();
        while (not c.getName().equals(FXBASE_CLASSNAME)) {
            fxClass = FXContext.getInstance().findClass(c.getCanonicalName());
            addPropertySession(node, fxClass, c.getSimpleName());
            
            c = c.getSuperclass();
        }
    }

    protected function addPropertySession(node: Node, fxClass: FXClassType, simpleClassName: String) {
        def section: PropertySection = new PropertySection(simpleClassName);
        
        def members = fxClass.getVariables(false);
        for (m in members) {
            //def objValue: FXObjectValue = FXContext.getInstance().mirrorOf(fxClass.getName()) as FXObjectValue;
            var objAttrValue: Object;
            try {
                def method : Method = node.getClass().getMethod("get${m.getName()}", []);
                objAttrValue = method.invoke(node);
            } catch(e: NoSuchMethodException) {
                continue;
            }

            section.addProperty(new Property(m.getName(), if (objAttrValue != null) objAttrValue else "null"));
        }

        section.setState(PropertySectionState.EXPANDED);
        model.addPropertySection(section);

        table.updateUI();
    }


    protected function createTreeNodes(): SwingComponent {
        treeNodes.setToggleClickCount(1);
        def treeNodesScrollPane = new JScrollPane(treeNodes);

        return SwingScrollPane {
            width: bind stage.width
            height: bind (stage.height/2) + 5
            view: SwingComponent.wrap(treeNodes);
        }

    }

    protected function createPanelProperties(): SwingComponent {
        model = new PropertyTableModel();
        table = new PropertyTable(model);
        table.setResizable(false, true);

        def panelProperties = new JPanel();
        panelProperties.setLayout(new BoxLayout(panelProperties, BoxLayout.Y_AXIS));
        panelProperties.add(table);

        return SwingScrollPane {
            width: bind stage.width
            height: bind (stage.height/2) - 55
            view: SwingComponent.wrap(panelProperties);
        }
    }


    protected function getComboBoxItems(registeredNodes: Node[]): SwingComboBoxItem[] {
        var items: SwingComboBoxItem[];
        for (n in registeredNodes) {
            insert SwingComboBoxItem {
                text: registeredNodesName[indexof n]
                value: n
                selected:true
            } into items;

        }

        return items;
    }


    protected function updateSceneGraphAction() : Void {
        if (sizeof registeredNodes > 0) {
            if (registeredNodesComboBox.selectedIndex > -1) {
                def selectedNode : Node = registeredNodesComboBox.selectedItem.value as Node;
                def name = registeredNodesName[Sequences.indexOf(registeredNodes, selectedNode)];

                def rootNode: DefaultMutableTreeNode = new DefaultMutableTreeNode(NodeViewRepresentation{node:selectedNode name:name});

                (treeNodes.getModel() as DefaultTreeModel).setRoot(rootNode);

                nodeHighlighting.ensureBoundingRectsAreRemoved();
                if (selectedNode instanceof Group) {
                    for (n in (selectedNode as Group).content) {
                        treatChildNode(rootNode, n);
                    }
                }

                nodeHighlighting.unregisterNodes();
                nodeHighlighting.registerNode(selectedNode);
            }
            else {
                Alert.inform("You must select a registered node!");
            }
        }
        else {
            Alert.inform("There's no registered nodes!");
        }
    }

    protected function treatChildNode(parentNode: DefaultMutableTreeNode, node: Node) : Void {
        var endName = "";
        if (node.id != null and node.id != "") {
            endName = " ({node.id})"
        }

        def newTreeNode = new DefaultMutableTreeNode(NodeViewRepresentation{node:node});
        parentNode.add(newTreeNode);

        if (node instanceof Group) {
            for (n in (node as Group).content) {
                treatChildNode(newTreeNode, n);
            }
        }
    }
}
