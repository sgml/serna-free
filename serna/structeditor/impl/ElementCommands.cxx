// 
// Copyright(c) 2009 Syntext, Inc. All Rights Reserved.
// Contact: info@syntext.com, http://www.syntext.com
// 
// This file is part of Syntext Serna XML Editor.
// 
// COMMERCIAL USAGE
// Licensees holding valid Syntext Serna commercial licenses may use this file
// in accordance with the Syntext Serna Commercial License Agreement provided
// with the software, or, alternatively, in accorance with the terms contained
// in a written agreement between you and Syntext, Inc.
// 
// GNU GENERAL PUBLIC LICENSE USAGE
// Alternatively, this file may be used under the terms of the GNU General 
// Public License versions 2.0 or 3.0 as published by the Free Software 
// Foundation and appearing in the file LICENSE.GPL included in the packaging 
// of this file. In addition, as a special exception, Syntext, Inc. gives you
// certain additional rights, which are described in the Syntext, Inc. GPL 
// Exception for Syntext Serna Free Edition, included in the file 
// GPL_EXCEPTION.txt in this package.
// 
// You should have received a copy of appropriate licenses along with this 
// package. If not, see <http://www.syntext.com/legal/>. If you are unsure
// which license is appropriate for your use, please contact the sales 
// department at sales@syntext.com.
// 
// This file is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE
// WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
// 
#include "structeditor/StructEditor.h"
#include "structeditor/impl/debug_se.h"
#include "structeditor/impl/XsUtils.h"
#include "structeditor/impl/EditPolicyImpl.h"
#include "structeditor/InsertTextEventData.h"
#include "genui/StructDocumentActions.hpp"

#include "common/PropertyTreeEventData.h"
#include "utils/GrovePosEventData.h"

#include "docview/SernaDoc.h"
#include "common/CommandEvent.h"
#include "common/PropertyTree.h"
#include "common/ScopeGuard.h"

#include "groveeditor/GrovePos.h"
#include "groveeditor/GroveEditor.h"
#include "groveeditor/GroveCommand.h"

#include "formatter/AreaPos.h"

#include "grove/Nodes.h"
#include "xs/XsNodeExt.h"

#include <qapplication.h>

using namespace Common;
using namespace GroveLib;
using namespace GroveEditor;

CommandPtr make_split_command(const GrovePos& pos, StructEditor* se)
{
    if (pos.isNull())
        return false;
    int sect_levels[Node::MAX_SECTION_ID];
    memset(sect_levels, 0, sizeof(sect_levels));
    const Node* node = (pos.type() == GrovePos::TEXT_POS)
        ? pos.node() : pos.before();
    for (; node; node = node->nextSibling()) {
        if (!(node->nodeType() & Node::SECT_NODE_MASK))
            continue;
        if (node->nodeType() & Node::SECT_END_BIT)
            --sect_levels[node->nodeType() & Node::SECT_TYPE_MASK];
        else
            ++sect_levels[node->nodeType() & Node::SECT_TYPE_MASK];
    }
    for (int i = 0; i < Node::MAX_SECTION_ID; ++i) {
        if (!sect_levels[i])
            continue;
        se->sernaDoc()->showMessageBox(
            SernaDoc::MB_CRITICAL,
            qApp->translate("StructEditor", "Cannot split entity or redline"),
            qApp->translate(
                "StructEditor", 
                "Splitting of entities and redlines is not allowed"),
            tr("&Ok"));
        return 0;
    }
    Element* elem = traverse_to_element(pos);
    if (se->isEditableEntity(GrovePos(elem), 
        StructEditor::ANY_OP|StructEditor::PARENT_OP) != StructEditor::POS_OK)
            return 0;
    if (elem->grove()->document()->documentElement() == elem)
        return 0;
    return se->groveEditor()->splitElement(pos);
}

///////////////////////////////////////////////////////////

SIMPLE_COMMAND_EVENT_IMPL(SplitElement, StructEditor)

bool SplitElement::doExecute(StructEditor* se, EventData*)
{
    CommandPtr split_cmd(make_split_command(se->editViewSrcPos(), se));
    if (split_cmd.isNull())
        return false;
    return se->executeAndUpdate(split_cmd);
}

///////////////////////////////////////////////////////////

static Node* element_node(Node* node)
{
    while (node && Node::ELEMENT_NODE != node->nodeType())
        node = node->parent();
    return node;
}

static int split_depth(StructEditor* se, const GrovePos& posBeforeSplit)
{
    if (posBeforeSplit.isNull())
        return 0;
    GrovePos curr_pos;
    if (!se->getCheckedPos(curr_pos,
        StructEditor::ANY_OP|StructEditor::SILENT_OP))
            return 0;
    Node* node = element_node(curr_pos.node());
    Node* before_split = element_node(posBeforeSplit.node());
    int i = 0;
    while (node) {
        if (before_split->parent() == node)
            return i;
        i++;
        node = node->parent();
    }
    return 0;
}

static bool do_advanced_split(StructEditor* se)
{
    EditPolicyImpl& ep = *se->editPolicy();
    GrovePos pos, curr_pos;
    if (!se->getCheckedPos(curr_pos, StructEditor::ANY_OP|
        StructEditor::PARENT_OP|StructEditor::SILENT_OP))
            return false;
    pos = curr_pos;
    //! Adjust position to first element ancestor
    while (!pos.isNull() && pos.type() != GrovePos::ELEMENT_POS)
        pos = GrovePos(pos.node()->parent(), pos.node());
    for (int c = ep.enterPressCount(); !pos.isNull() && 0 != c; --c)
        pos = GrovePos(pos.node()->parent(), pos.node());
    if (pos.isNull())
        return false;
    CommandPtr split_cmd(make_split_command(pos, se));
    if (split_cmd.isNull())
        return false;
    RefCntPtr<GroveBatchCommand> batch_cmd(new GroveBatchCommand);
    batch_cmd->setSuggestedPos(curr_pos);
    batch_cmd->setUndoPos(curr_pos);
    batch_cmd->executeAndAdd(split_cmd.pointer());
    if (se->executeAndUpdate(batch_cmd.pointer())) {
        ep.setEnterPressCount(split_depth(se, pos));
        return true;
    } else 
        ep.setEnterPressCount(0);
    return false;
}

SIMPLE_COMMAND_EVENT_IMPL(AdvSplitElement,  StructEditor)
SIMPLE_COMMAND_EVENT_IMPL(ProcessKeyReturn, StructEditor)

bool AdvSplitElement::doExecute(StructEditor* se, EventData*)
{
    EditPolicyImpl& ep = *se->editPolicy();
    if (makeCommand<ProcessKeyReturn>()->execute(se))
        return true;
    if (0 < ep.enterPressCount()) 
        do_advanced_split(se);
    else {
        if (makeCommand<SplitElement>()->execute(se))
            ep.setEnterPressCount(split_depth(se, se->editViewSrcPos()));
    }
    return true;
}

///////////////////////////////////////////////////////////

SIMPLE_COMMAND_EVENT_IMPL(JoinElements, StructEditor)

bool JoinElements::doExecute(StructEditor* se, EventData*)
{
    GrovePos pos;
    if (!se->getCheckedPos(pos))
        return false;
    if (pos.type() != GrovePos::ELEMENT_POS || !pos.before())
        return false;
    Node* n = pos.before()->prevSibling();
    if (0 == n || n->nodeType() != GroveLib::Node::ELEMENT_NODE ||
        pos.before()->nodeType() != GroveLib::Node::ELEMENT_NODE
        || n->nodeName() != pos.before()->nodeName())
            return false;
    bool different_attrs = false;
    GroveLib::Attr* attr = ELEMENT_CAST(pos.before())->attrs().firstChild();
    for (; attr; attr = attr->nextSibling()) {
        GroveLib::Attr* nattr = ELEMENT_CAST(n)->attrs().firstChild();
        for (; nattr; nattr = nattr->nextSibling()) {
            if (attr->nodeName() == nattr->nodeName() &&
                attr->value() != nattr->value()) {
                different_attrs = true;
                break;
            }
        }
    }

    if (different_attrs)
        se->sernaDoc()->showMessageBox(SernaDoc::MB_CRITICAL,
            tr("Warning"),
            tr("The joined elements have conflicting attributes.\n"
               "First element's attributes will be used."), tr("&Ok"));

    return se->executeAndUpdate(se->groveEditor()->joinElements(n));
}

///////////////////////////////////////////////////////////

SIMPLE_COMMAND_EVENT_IMPL(UntagElement, StructEditor)

bool UntagElement::doExecute(StructEditor* se, EventData*)
{
    GrovePos pos;
    if (!se->getCheckedPos(pos, 
        StructEditor::STRUCT_OP|StructEditor::PARENT_OP))
            return false;
    Element* elem = traverse_to_element(pos);
    if (se->isEditableEntity(GrovePos(elem), StructEditor::STRUCT_OP|
        StructEditor::PARENT_OP) != StructEditor::POS_OK)
            return false;
    if (elem->grove()->document()->documentElement() == elem)
        return false;
    return se->executeAndUpdate(se->groveEditor()->untag(pos));
}

///////////////////////////////////////////////////////////

class ShowEditPiDialog;

SIMPLE_COMMAND_EVENT_IMPL(InsertPi, StructEditor)

bool InsertPi::doExecute(StructEditor* se, EventData*)
{
    GrovePos pos;
    if (!se->getCheckedPos(pos))
        return false;
    PropertyTreeEventData ed;
    ed.root()->makeDescendant("target",  String(""));
    ed.root()->makeDescendant("caption", tr("Insert PI"));
    if (!makeCommand<ShowEditPiDialog>(&ed)->execute(se, &ed))
        return false;
    return se->executeAndUpdate(
        se->groveEditor()->insertPi(
            pos, ed.root()->getSafeProperty("target")->getString(),
            ed.root()->getSafeProperty("data")->getString()));
}
///////////////////////////////////////////////////////////

SIMPLE_COMMAND_EVENT_IMPL(EditPi, StructEditor)

bool EditPi::doExecute(StructEditor* se, EventData*)
{
    GroveEditor::GrovePos pos(se->editViewSrcPos());
    StructEditor::PositionStatus pos_status = se->isEditableEntity(pos,
        StructEditor::ANY_OP|StructEditor::ALLOW_RDONLY);
    if (pos_status == StructEditor::POS_FAIL || 
        pos.node()->nodeType() != Node::PI_NODE)
            return false;
    ProcessingInstruction* pn = static_cast<ProcessingInstruction*>(pos.node());
    PropertyTreeEventData ed;
    ed.root()->makeDescendant("data",   pn->data());
    ed.root()->makeDescendant("target", pn->target());
    ed.root()->makeDescendant("caption", tr("Edit PI"));
    if (pos_status == StructEditor::POS_RDONLY)
        ed.root()->makeDescendant("is-readonly");
    if (!makeCommand<ShowEditPiDialog>(&ed)->execute(se, &ed))
        return false;
    if (pos_status == StructEditor::POS_RDONLY)
        return true;
    return se->executeAndUpdate(
        se->groveEditor()->changePi(
            pos, ed.root()->getSafeProperty("target")->getString(),
            ed.root()->getSafeProperty("data")->getString()));
}

///////////////////////////////////////////////////////////

SIMPLE_COMMAND_EVENT_IMPL(InsertComment, StructEditor)

class ShowEditCommentDialog;

bool InsertComment::doExecute(StructEditor* se, EventData*)
{
    GroveEditor::GrovePos pos;
    if (!se->getCheckedPos(pos))
        return false;
    PropertyTreeEventData ed;
    ed.root()->makeDescendant("caption", tr("Insert Comment"));
    if (!makeCommand<ShowEditCommentDialog>(&ed)->execute(se, &ed))
        return false;
    return se->executeAndUpdate(se->groveEditor()->insertComment(pos,
        ed.root()->getSafeProperty("data")->getString()));
}

///////////////////////////////////////////////////////////

SIMPLE_COMMAND_EVENT_IMPL(EditComment, StructEditor)

bool EditComment::doExecute(StructEditor* se, EventData*)
{
    GroveEditor::GrovePos pos(se->editViewSrcPos());
    StructEditor::PositionStatus pos_status = se->isEditableEntity(pos,
        StructEditor::ANY_OP|StructEditor::ALLOW_RDONLY);
    if (pos_status == StructEditor::POS_FAIL || 
        pos.node()->nodeType() != Node::COMMENT_NODE)
            return false;
    Comment* cn = static_cast<Comment*>(pos.node());
    PropertyTreeEventData ed;
    ed.root()->makeDescendant("data", cn->comment());
    ed.root()->makeDescendant("caption", tr("Edit Comment"));
    if (pos_status == StructEditor::POS_RDONLY)
        ed.root()->makeDescendant("is-readonly");
    if (!makeCommand<ShowEditCommentDialog>(&ed)->execute(se, &ed))
        return false;
    if (pos_status == StructEditor::POS_RDONLY)
        return true;
    return se->executeAndUpdate(se->groveEditor()->changeComment(pos,
        ed.root()->getSafeProperty("data")->getString()));
}

///////////////////////////////////////////////////////////

class InsertElement;
class InsertText;
class UnfoldElement;

bool ProcessKeyReturn::doExecute(StructEditor* se, EventData*)
{
    using namespace Formatter;
    EditPolicyImpl& ep = *se->editPolicy();
    ScopeGuard enter_flag_guard(
        makeObjGuard(ep, &EditPolicyImpl::setEnterPressCount, 0));
    const AreaPos& area_pos = se->editableView().context().areaPos();
    if (CHOICE_AREA == area_pos.area()->type()) {
        makeCommand<InsertElement>()->execute(se);
        return true;
    }
    if (area_pos.area()->chain()->isPreserveLinefeed()) {
        InsertTextEventData ed("\n", ep.textContinued());
        makeCommand<InsertText>(&ed)->execute(se);
        ep.continueText();
        return true;
    }
    if (PI_AREA == area_pos.area()->type())
        makeCommand<EditPi>()->execute(se);
    else if (COMMENT_AREA == area_pos.area()->type())
        makeCommand<EditComment>()->execute(se);
    else if (FOLD_AREA == area_pos.area()->type())
        makeCommand<UnfoldElement>()->execute(se);
    else if (COMBO_BOX_AREA == area_pos.area()->type() ||
             LINE_EDIT_AREA == area_pos.area()->type())
        edit_simple_form_area(se);
    else {
        enter_flag_guard.dismiss();
        return false;
    }
    return true;
}


