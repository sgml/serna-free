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
// Copyright (c) 2004 Syntext Inc.
//
// This is a copyrighted commercial software.
// Please see COPYRIGHT file for details.

#ifndef SERNA_UTILS_HELP_ASSISTANT_H_
#define SERNA_UTILS_HELP_ASSISTANT_H_

#include "utils/utils_defs.h"
#include "common/String.h"

namespace Common {
    class PropertyNode;
}

class UTILS_EXPIMP HelpAssistant {
public:
    virtual ~HelpAssistant() {}

    /// shows the reference for the ADP file
    virtual void    show(const Common::String& ref,
                const Common::String& adp = Common::String()) const = 0;

    /// Calls Qt Assitant with the long help specified by property mode
    virtual void    showLongHelp(const Common::PropertyNode*,
            const Common::String& desc = Common::String()) const = 0;
};

/// Accessor to helpAssistant singleton. With this, access to help utility
/// is like that: helpAssistant().show("blah");
UTILS_EXPIMP HelpAssistant& helpAssistant();

#endif // SERNA_UTILS_HELP_ASSISTANT_H
