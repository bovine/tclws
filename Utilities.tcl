###############################################################################
##                                                                           ##
##  Copyright (c) 2006-2008, Gerald W. Lester                                ##
##  Copyright (c) 2008, Georgios Petasis                                     ##
##  Copyright (c) 2006, Visiprise Software, Inc                              ##
##  Copyright (c) 2006, Arnulf Wiedemann                                     ##
##  Copyright (c) 2006, Colin McCormack                                      ##
##  Copyright (c) 2006, Rolf Ade                                             ##
##  Copyright (c) 2001-2006, Pat Thoyts                                      ##
##  All rights reserved.                                                     ##
##                                                                           ##
##  Redistribution and use in source and binary forms, with or without       ##
##  modification, are permitted provided that the following conditions       ##
##  are met:                                                                 ##
##                                                                           ##
##    * Redistributions of source code must retain the above copyright       ##
##      notice, this list of conditions and the following disclaimer.        ##
##    * Redistributions in binary form must reproduce the above              ##
##      copyright notice, this list of conditions and the following          ##
##      disclaimer in the documentation and/or other materials provided      ##
##      with the distribution.                                               ##
##    * Neither the name of the Visiprise Software, Inc nor the names        ##
##      of its contributors may be used to endorse or promote products       ##
##      derived from this software without specific prior written            ##
##      permission.                                                          ##
##                                                                           ##
##  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS      ##
##  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT        ##
##  LIMITED  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS       ##
##  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE           ##
##  COPYRIGHT OWNER OR  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,     ##
##  INCIDENTAL, SPECIAL,  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,    ##
##  BUT NOT LIMITED TO,  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;        ##
##  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER         ##
##  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT       ##
##  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR  OTHERWISE) ARISING IN       ##
##  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF  ADVISED OF THE         ##
##  POSSIBILITY OF SUCH DAMAGE.                                              ##
##                                                                           ##
###############################################################################

package require Tcl 8.4
if {![llength [info command dict]]} {
    package require dict
}
package require log
package require tdom 0.8
package require struct::set

package provide WS::Utils 1.4.0

namespace eval ::WS {}

namespace eval ::WS::Utils {
    set typeInfo {}
    set currentSchema {}
    array set importedXref {}
    set nsList {
        w http://schemas.xmlsoap.org/wsdl/
        d http://schemas.xmlsoap.org/wsdl/soap/
        s http://www.w3.org/2001/XMLSchema
    }
    array set simpleTypes {
        string 1
        boolean 1
        decimal 1
        float 1
        double 1
        duration 1
        dateTime 1
        time 1
        date 1
        gYearMonth 1
        gYear 1
        gMonthDay 1
        gDay 1
        gMonth 1
        hexBinary 1
        base64Binary 1
        anyURI 1
        QName 1
        NOTATION 1
        normalizedString 1
        token 1
        language 1
        NMTOKEN 1
        NMTOKENS 1
        Name 1
        NCName 1
        ID 1
        IDREF 1
        IDREFS 1
        ENTITY 1
        ENTITIES 1
        integer 1
        nonPositiveInteger 1
        negativeInteger 1
        long 1
        int 1
        short 1
        byte 1
        nonNegativeInteger 1
        unsignedLong 1
        unsignedInt 1
        unsignedShort 1
        unsignedByte 1
        positiveInteger 1
    }
    array set options {
        UseNS 1
        StrictMode error
        parseInAttr 0
        genOutAttr 0
    }

    set standardAttributes {
        baseType
        comment
        pattern
        length
        fixed
        maxLength
        minLength
        minInclusive
        maxInclusive
        enumeration
        type
    }

}



###########################################################################
#
# Public Procedure Header - as this procedure is modified, please be sure
#                           that you update this header block. Thanks.
#
#>>BEGIN PUBLIC<<
#
# Procedure Name : ::WS::Utils::GetCrossreference
#
# Description : Get the type cross reference information for a service.
#
# Arguments :
#       mode            - Client|Server
#       service         - The name of the service
#
# Returns : A dictionary of cross reference information
#
# Side-Effects : None
#
# Exception Conditions : None
#
# Pre-requisite Conditions : None
#
# Original Author : Gerald W. Lester
#
#>>END PUBLIC<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  07/06/2006  G.Lester     Initial version
#
#
###########################################################################
proc ::WS::Utils::GetCrossreference {mode service} {
    variable typeInfo

    array set crossreference {}

    dict for {type typeDict} [dict get $typeInfo $mode $service] {
        foreach {field fieldDict} [dict get $typeDict definition] {
            set fieldType [string trimright [dict get $fieldDict type] {()}]
            incr crossreference($fieldType,count)
            lappend crossreference($fieldType,usedBy) $type.$field
        }
        if {![info exists crossreference($type,count) ]} {
            set crossreference($type,count) 0
            set crossreference($type,usedBy) {}
        }
    }

    return [array get crossreference]
}

###########################################################################
#
# Public Procedure Header - as this procedure is modified, please be sure
#                           that you update this header block. Thanks.
#
#>>BEGIN PUBLIC<<
#
# Procedure Name : ::WS::Utils::SetOption
#
# Description : Define a type for a service.
#
# Arguments :
#       option        - option
#       value         - value (optional)
#
# Returns : Nothing
#
# Side-Effects : None
#
# Exception Conditions : None
#
# Pre-requisite Conditions : None
#
# Original Author : Gerald W. Lester
#
#>>END PUBLIC<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  07/06/2006  G.Lester     Initial version
#
#
###########################################################################
proc ::WS::Utils::SetOption {args} {
    variable options

    if {[llength $args] == 0} {
        ::log::log debug {Return all options}
        return [array get options]
    } elseif {[llength $args] == 1} {
        set opt [lindex $args 0]
        ::log::log debug "One Option {$opt}"
        if {[info exists options($opt)]} {
            return $options($opt)
        } else {
            ::log::log debug "Unkown option {$opt}"
            return \
                -code error \
                -errorcode [list WS CLIENT UNKOPTION $opt] \
                "Unknown option'$opt'"
        }
    } elseif {([llength $args] % 2) == 0} {
        ::log::log debug {Multiple option pairs}
        foreach {opt value} $args {
            if {[info exists options($opt)]} {
                ::log::log debug "Setting Option {$opt} to {$value}"
                set options($opt) $value
            } else {
                ::log::log debug "Unkown option {$opt}"
                return \
                    -code error \
                    -errorcode [list WS CLIENT UNKOPTION $opt] \
                    "Unknown option'$opt'"
            }
        }
    } else {
        ::log::log debug "Bad number of arguments {$args}"
        return \
            -code error \
            -errorcode [list WS CLIENT INVARGCNT $args] \
            "Invalid argument count'$args'"
    }
    return;
}

###########################################################################
#
# Public Procedure Header - as this procedure is modified, please be sure
#                           that you update this header block. Thanks.
#
#>>BEGIN PUBLIC<<
#
# Procedure Name : ::WS::Utils::ServiceTypeDef
#
# Description : Define a type for a service.
#
# Arguments :
#       mode            - Client|Server
#       service         - The name of the service this type definition is for
#       type            - The type to be defined/redefined
#       definition      - The definition of the type's fields.  This consist of one
#                         or more occurance of a field definition.  Each field definition
#                         consist of:  fieldName fieldInfo
#                         Where field info is: {type typeName comment commentString}
#                           typeName can be any simple or defined type.
#                           commentString is a quoted string describing the field.
#       xns             - The namespace
#
# Returns : Nothing
#
# Side-Effects : None
#
# Exception Conditions : None
#
# Pre-requisite Conditions : None
#
# Original Author : Gerald W. Lester
#
#>>END PUBLIC<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  07/06/2006  G.Lester     Initial version
#
#
###########################################################################
proc ::WS::Utils::ServiceTypeDef {mode service type definition {xns {}}} {
    ::log::log debug [info level 0]
    variable typeInfo

    if {![string length $xns]} {
        set xns $service
    }
    dict set typeInfo $mode $service $type definition $definition
    dict set typeInfo $mode $service $type xns $xns
    return;
}

###########################################################################
#
# Public Procedure Header - as this procedure is modified, please be sure
#                           that you update this header block. Thanks.
#
#>>BEGIN PUBLIC<<
#
# Procedure Name : ::WS::Utils::MutableTypeDef
#
# Description : Define a mutalbe type for a service.
#
# Arguments :
#       mode            - Client|Server
#       service         - The name of the service this type definition is for
#       type            - The type to be defined/redefined
#       fromSwitchCmd   - The cmd to deternmine the actaul type when converting
#                         from DOM to a dictionary.  The actual call will have
#                         the following arguments appended to the command:
#                           mode service type xns DOMnode
#       toSwitchCmd     - The cmd to deternmine the actaul type when converting
#                         from a dictionary to a DOM.  The actual call will have
#                         the following arguments appended to the command:
#                           mode service type xns remainingDictionaryTree
#       xns             - The namespace
#
# Returns : Nothing
#
# Side-Effects : None
#
# Exception Conditions : None
#
# Pre-requisite Conditions : None
#
# Original Author : Gerald W. Lester
#
#>>END PUBLIC<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  02/15/2008  G.Lester     Initial version
#
#
###########################################################################
proc ::WS::Utils::MutableTypeDef {mode service type fromSwitchCmd toSwitchCmd {xns {}}} {
    variable mutableTypeInfo

    if {![string length $xns]} {
        set xns $service
    }
    set mutableTypeInfo([list $mode $service $type]) \
        [list $fromSwitchCmd $toSwitchCmd]
    return;
}

###########################################################################
#
# Public Procedure Header - as this procedure is modified, please be sure
#                           that you update this header block. Thanks.
#
#>>BEGIN PUBLIC<<
#
# Procedure Name : ::WS::Utils::ServiceSimpleTypeDef
#
# Description : Define a type for a service.
#
# Arguments :
#       mode            - Client|Server
#       service         - The name of the service this type definition is for
#       type            - The type to be defined/redefined
#       definition      - The definition of the type's fields.  This consist of one
#                         or more occurance of a field definition.  Each field definition
#                         consist of:  fieldName fieldInfo
#                         Where field info is list of name value:
#                           basetype typeName - any simple or defined type.
#                           comment commentString - a quoted string describing the field.
#                           pattern value
#                           length value
#                           fixed "true"|"false"
#                           maxLength value
#                           minLength value
#                           minInclusive value
#                           maxInclusive value
#                           enumeration value
#
#       xns             - The namespace
#
# Returns : Nothing
#
# Side-Effects : None
#
# Exception Conditions : None
#
# Pre-requisite Conditions : None
#
# Original Author : Gerald W. Lester
#
#>>END PUBLIC<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  07/06/2006  G.Lester     Initial version
#
#
###########################################################################
proc ::WS::Utils::ServiceSimpleTypeDef {mode service type definition {xns {tns1}}} {
    variable simpleTypes
    variable typeInfo

    if {![dict exists $definition xns]} {
        set simpleTypes($mode,$service,$type) [concat $definition xns $xns]
    } else {
        set simpleTypes($mode,$service,$type) $definition
    }
    if {[dict exists $typeInfo $mode $service]} {
        dict unset typeInfo $mode $service $type
    }
    return;
}

###########################################################################
#
# Public Procedure Header - as this procedure is modified, please be sure
#                           that you update this header block. Thanks.
#
#>>BEGIN PUBLIC<<
#
# Procedure Name :      ::WS::Utils::GetServiceTypeDef
#
# Description : Query for type definitions.
#
# Arguments :
#       mode            - Client|Server
#       service         - The name of the service this query is for
#       type            - The type to be retrieved (optional)
#
# Returns :
#       If type not provided, a dictionary object describing all of the complex types
#       for the service.
#       If type provided, a dictionary object describing the type.
#         A definition consist of a dictionary object with the following key/values:
#           xns         - The namespace for this type.
#           definition  - The definition of the type's fields.  This consist of one
#                         or more occurance of a field definition.  Each field definition
#                         consist of:  fieldName fieldInfo
#                         Where field info is: {type typeName comment commentString}
#                         Where field info is list of name value:
#                           basetype typeName - any simple or defined type.
#                           comment commentString - a quoted string describing the field.
#                           pattern value
#                           length value
#                           fixed "true"|"false"
#                           maxLength value
#                           minLength value
#                           minInclusive value
#                           maxInclusive value
#                           enumeration value
#
# Side-Effects :        None
#
# Exception Conditions :        None
#
# Pre-requisite Conditions :    The service must be defined.
#
# Original Author : Gerald W. Lester
#
#>>END PUBLIC<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  07/06/2006  G.Lester     Initial version
#
#
###########################################################################
proc ::WS::Utils::GetServiceTypeDef {mode service {type {}}} {
    variable typeInfo
    variable simpleTypes

    if {[string equal $type {}]} {
        set results [dict get $typeInfo $mode $service]
    } else {
        set typeInfoList [TypeInfo $mode $service $type]
        if {[lindex $typeInfoList 0] == 0} {
            if {[info exists simpleTypes($mode,$service,$type)]} {
                set results $simpleTypes($mode,$service,$type)
            } elseif {[info exists simpleTypes($type)]} {
                set results [list type $type]
            } else {
                set results {}
            }
        } else {
            set results [dict get $typeInfo $mode $service $type]
        }
    }

    return $results
}

###########################################################################
#
# Public Procedure Header - as this procedure is modified, please be sure
#                           that you update this header block. Thanks.
#
#>>BEGIN PUBLIC<<
#
# Procedure Name :      ::WS::Utils::GetServiceSimpleTypeDef
#
# Description : Query for type definitions.
#
# Arguments :
#       mode            - Client|Server
#       service         - The name of the service this query is for
#       type            - The type to be retrieved (optional)
#
# Returns :
#       If type not provided, a dictionary object describing all of the simple types
#       for the service.
#       If type provided, a dictionary object describing the type.
#         A definition consist of a dictionary object with the following key/values:
#           xns         - The namespace for this type.
#           definition  - The definition of the type's fields.  This consist of one
#                         or more occurance of a field definition.  Each field definition
#                         consist of:  fieldName fieldInfo
#                         Where field info is: {type typeName comment commentString}
#                         Where field info is list of name value and any restrictions:
#                           basetype typeName - any simple or defined type.
#                           comment commentString - a quoted string describing the field.
#                           pattern value
#                           length value
#                           fixed "true"|"false"
#                           maxLength value
#                           minLength value
#                           minInclusive value
#                           maxInclusive value
#                           enumeration value
#
# Side-Effects :        None
#
# Exception Conditions :        None
#
# Pre-requisite Conditions :    The service must be defined.
#
# Original Author : Gerald W. Lester
#
#>>END PUBLIC<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  07/06/2006  G.Lester     Initial version
#
#
###########################################################################
proc ::WS::Utils::GetServiceSimpleTypeDef {mode service {type {}}} {
    variable simpleTypes

    if {[string equal $type {}]} {
        set results {}
        foreach {key value} [array get simpleTypes $mode,$service,*] {
            lappend results [list [lindex [split $key {,}] end] $simpleTypes($key)]
        }
    } else {
        if {[info exists simpleTypes($mode,$service,$type)]} {
            set results $simpleTypes($mode,$service,$type)
        } elseif {[info exists simpleTypes($type)]} {
            set results [list type $type]
        } else {
            return \
                -code error \
                -errorcode [list WS CLIENT UNKSMPTYP $type] \
                "Unknown simple type '$type'"
        }
    }

    return $results
}

###########################################################################
#
# Private Procedure Header - as this procedure is modified, please be sure
#                            that you update this header block. Thanks.
#
#>>BEGIN PUBLIC<<
#
# Procedure Name : ::WS::Utils::ProcessImportXml
#
# Description : Parse the bindings for a service from a WSDL into our
#               internal representation
#
# Arguments :
#    mode           - The mode, Client or Server
#    xml            - The XML string to parse
#    serviceName    - The name service.
#    serviceInfoVar - The name of the dictionary containing the partially
#                     parsed service.
#    tnsCountVar    - The name of the variable containing the count of the
#                     namespace.
#
# Returns : Nothing
#
# Side-Effects : Defines Client mode types for the service as specified by the WSDL
#
# Exception Conditions : None
#
# Pre-requisite Conditions : None
#
# Original Author : Gerald W. Lester
#
#>>END PRIVATE<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  08/06/2006  G.Lester     Initial version
#
#
###########################################################################
proc ::WS::Utils::ProcessImportXml {mode baseUrl xml serviceName serviceInfoVar tnsCountVar} {
    ::log::log debug "Entering ProcessImportXml $mode $baseUrl $xml $serviceName $serviceInfoVar $tnsCountVar"
    upvar $serviceInfoVar serviceInfo
    upvar $tnsCountVar tnsCount
    variable currentSchema

    if {[catch {dom parse $xml doc}]} {
        set first [string first {?>} $xml]
        incr first 2
        set xml [string range $xml $first end]
        dom parse $xml doc
    }
    $doc selectNodesNamespaces {
        w http://schemas.xmlsoap.org/wsdl/
        d http://schemas.xmlsoap.org/wsdl/soap/
        s http://www.w3.org/2001/XMLSchema
    }
    $doc documentElement schema
    set prevSchema $currentSchema
    set currentSchema $schema

    parseScheme $mode $baseUrl $schema $serviceName serviceInfo tnsCount

    set currentSchema $prevSchema
    $doc delete
}

###########################################################################
#
# Private Procedure Header - as this procedure is modified, please be sure
#                            that you update this header block. Thanks.
#
#>>BEGIN PUBLIC<<
#
# Procedure Name : ::WS::Utils::TypeInfo
#
# Description : Return a list indicating if the type is simple or complex
#               and if it is a scalar or an array.
#
# Arguments :
#    type       - the type name, possiblely with a () to specify it is an array
#
# Returns : A list of two elements, as follows:
#               0|1 - 0 means a simple type, 1 means a complex type
#               0|1 - 0 means a scalar, 1 means an array
#
# Side-Effects : None
#
# Exception Conditions : None
#
# Pre-requisite Conditions : None
#
# Original Author : Gerald W. Lester
#
#>>END PUBLIC<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  07/06/2006  G.Lester     Initial version
#
#
###########################################################################
proc ::WS::Utils::TypeInfo {mode service type} {
    variable simpleTypes
    variable typeInfo

    set type [string trim $type]
    if {[string equal [string range $type end-1 end] {()}]} {
        set isArray 1
        set type [string range $type 0 end-2]
    } elseif {[string equal $type {array}]} {
        set isArray 1
    } else {
        set isArray 0
    }
    set isNotSimple [dict exists $typeInfo $mode $service $type]
    return [list $isNotSimple $isArray]
}


###########################################################################
#
# Public Procedure Header - as this procedure is modified, please be sure
#                           that you update this header block. Thanks.
#
#>>BEGIN PUBLIC<<
#
# Procedure Name : ::WS::CheckAndBuild::ValidateRequest
#
# Description : Given a schema validate a XML string given as parameter
#               using a XML schema description (in WS:: form) for
#               validation
#
# Arguments :
#       mode        - Client/Server
#       serviceName - The service name
#       xmlString   - The XML string to validate
#       tagName     - The name of the starting tag
#       typeName    - The type for the tag
#
# Returns :     1 if valition ok, 0 if not
#
# Side-Effects :
#       ::errorCode - cleared if validation ok
#                   - contains validation failure information if validation
#                       failed.
#
# Exception Conditions :
#       WS CHECK START_NODE_DIFFERS - Start node not what was expected
#
# Pre-requisite Conditions :    None
#
# Original Author : Arnulf Wiedemann
#
#>>END PUBLIC<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  08/14/2006  A.Wiedemann  Initial version
#       2  08/18/2006  G.Lester     Generalized to handle qualified XML
#
#
###########################################################################
proc ::WS::Utils::Validate {mode serviceName xmlString tagName typeName} {

    dom parse $xmlString resultTree
    $resultTree documentElement currNode
    set nodeName [$currNode localName]
    if {![string equal $nodeName $tagName]} {
        return \
            -code error \
            -errorcode [list WS CHECK START_NODE_DIFFERS [list $tagName $nodeName]] \
            "start node differs expected: $tagName found: $nodeName"
    }
    set ::errorCode {}
    set result [checkTags $mode $serviceName $currNode $typeName]
    $resultTree delete
    return $result
}

###########################################################################
#
# Public Procedure Header - as this procedure is modified, please be sure
#                           that you update this header block. Thanks.
#
#>>BEGIN PUBLIC<<
#
# Procedure Name : ::WS::Utils::BuildRequest
#
# Description : Given a schema check the body of a request handed in
#               as a XML string using a XML schema description (in WS:: form)
#               for validation
#
# Arguments :
#       mode        - Client/Server
#       serviceName - The service name
#       tagName     - The name of the starting tag
#       typeName    - The type for the tag
#       valueInfos  - The dictionary of the values
#
# Returns :     The body of the request as xml
#
# Side-Effects :        None
#
# Exception Conditions :        None
#
# Pre-requisite Conditions :    None
#
# Original Author : Arnulf Wiedemann
#
#>>END PUBLIC<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  08/13/2006  A.Wiedemann  Initial version
#       2  08/18/2006  G.Lester     Generalized to generate qualified XML
#
###########################################################################
proc ::WS::Utils::BuildRequest {mode serviceName tagName typeName valueInfos} {
    upvar $valueInfos values
    variable resultTree
    variable currNode

    set resultTree [::dom createDocument $tagName]
    set typeInfo [GetServiceTypeDef $mode $serviceName $typeName]
    $resultTree documentElement currNode
    if {[catch {buildTags $mode $serviceName $typeName $valueInfos $resultTree $currNode} msg]} {
        set tmpErrorCode $::errorCode
        set tmpErrorInfo $::errorInfo
        $resultTree delete
        return \
            -code error \
            -errorcode $tmpErrorCode \
            -errorinfo $tmpErrorInfo \
            $msg
    }
    set xml [$resultTree asXML]
    $resultTree delete
    return $xml
}


###########################################################################
#
# Public Procedure Header - as this procedure is modified, please be sure
#                           that you update this header block. Thanks.
#
#>>BEGIN PUBLIC<<
#
# Procedure Name : ::WS::Server::GenerateXsd
#
# Description : Generate a XSD.  NOTE -- does not write a file
#
# Arguments :
#       mode            - Client/Server
#       serviceName     - The service name
#       targetNamespace - Target namespace
#
# Returns :     XML of XSD
#
# Side-Effects :        None
#
# Exception Conditions :        None
#
# Pre-requisite Conditions :    Service must exists
#
# Original Author : Gerald W. Lester
#
#>>END PUBLIC<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  02/03/2008  G.Lester     Initial Version
#
###########################################################################
proc ::WS::Utils::GenerateXsd {mode serviceName targetNamespace} {
    set reply [::dom createDocument definitions]
    $reply documentElement definition

    GenerateScheme $mode $serviceName $reply {} $targetNamespace

    append msg \
        {<?xml version="1.0"  encoding="utf-8"?>} \
        "\n" \
        [$reply asXML  -indent 4 -escapeNonASCII -doctypeDeclaration 0]
    $reply delete
    return $msg
}

###########################################################################
#
# Public Procedure Header - as this procedure is modified, please be sure
#                           that you update this header block. Thanks.
#
#>>BEGIN PUBLIC<<
#
# Procedure Name : ::WS::Utils::GenerateScheme
#
# Description : Generate a scheme
#
# Arguments :
#       mode            - Client/Server
#       serviceName     - The service name
#       doc             - The document to add the scheme to
#       parent          - The parent node of the scheme
#       targetNamespace - Target namespace
#
# Returns :     nothing
#
# Side-Effects :        None
#
# Exception Conditions :        None
#
# Pre-requisite Conditions :    None
#
# Original Author : Gerald W. Lester
#
#>>END PUBLIC<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  02/15/2008  G.Lester     Made Scheme generation a utility
#       2  02/03/2008  G.Lester     Moved scheme generation into WS::Utils namespace
#
###########################################################################
proc ::WS::Utils::GenerateScheme {mode serviceName doc parent targetNamespace} {

    set localTypeInfo [GetServiceTypeDef $mode $serviceName]
    array set typeArr {}
    foreach type [dict keys $localTypeInfo] {
        set typeArr($type) 1
    }
    if {[string equal $parent {}]} {
        $doc documentElement schema
        $schema setAttribute \
            xmlns:s         "http://www.w3.org/2001/XMLSchema"
    } else {
        $parent appendChild [$doc createElement s:schema schema]
    }
    $schema setAttribute \
        elementFormDefault qualified \
        targetNamespace $targetNamespace

    foreach baseType [lsort -dictionary [array names typeArr]] {
        ::log::log debug "Outputing $baseType"
        $schema appendChild [$doc createElement s:element elem]
        $elem setAttribute name $baseType
        $elem setAttribute type ${serviceName}:${baseType}
        $schema appendChild [$doc createElement s:complexType comp]
        $comp setAttribute name $baseType
        $comp appendChild [$doc createElement s:sequence seq]
        set baseTypeInfo [dict get $localTypeInfo $baseType definition]
        ::log::log debug "\t parts {$baseTypeInfo}"
        foreach {field tmpTypeInfo} $baseTypeInfo {
            $seq appendChild  [$doc createElement s:element tmp]
            set tmpType [dict get $tmpTypeInfo type]
            ::log::log debug "Field $field of $tmpType"
            foreach {name value} [getTypeWSDLInfo $mode $serviceName $field $tmpType] {
                $tmp setAttribute $name $value
            }
        }
    }
}


###########################################################################
#
# Private Procedure Header - as this procedure is modified, please be sure
#                            that you update this header block. Thanks.
#
#>>BEGIN PRIVATE<<
#
# Procedure Name : ::WS::Server::getTypeWSDLInfo
#
# Description : Return full type information usable for a WSDL
#
# Arguments :
#     mode        - Client/Server
#    serviceName        - The name of the service
#    field              - The field name
#    type               - The data type
#
# Returns : The type definition as a dictionary object
#
# Side-Effects : None
#
# Exception Conditions : None
#
# Pre-requisite Conditions : None
#
# Original Author : Gerald W. Lester
#
#>>END PRIVATE<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  07/06/2006  G.Lester     Initial version
#       2  02/03/2008  G.Lester     Moved  into WS::Utils namespace
#
###########################################################################
proc ::WS::Utils::getTypeWSDLInfo {mode serviceName field type} {
    set typeInfo {maxOccurs 1 minOccurs 1 name * type *}
    dict set typeInfo name $field
    set typeList [TypeInfo $mode $serviceName $type]
    if {[lindex $typeList 0] == 0} {
        dict set typeInfo type s:[string trimright $type {()}]
    } else {
        dict set typeInfo type $serviceName:[string trimright $type {()}]
    }
    if {[lindex $typeList 1]} {
        dict set typeInfo maxOccurs unbounded
    }

    return $typeInfo
}


###########################################################################
#
# Private Procedure Header - as this procedure is modified, please be sure
#                            that you update this header block. Thanks.
#
#>>BEGIN PRIVATE<<
#
# Procedure Name : ::WS::Utils::convertTypeToDict
#
# Description : Convert the XML, in DOM representation, to a dictionary object for
#               a given type.
#
# Arguments :
#    mode        - The mode, Client or Server
#    serviceName - The service name the type is defined in
#    node        - The base node for the type.
#    type        - The name of the type
#    root        - The root node of the document
#
# Returns : A dictionary object for a given type.
#
# Side-Effects : None
#
# Exception Conditions : None
#
# Pre-requisite Conditions : None
#
# Original Author : Gerald W. Lester
#
#>>END PRIVATE<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  07/06/2006  G.Lester     Initial version
#
#
###########################################################################
proc ::WS::Utils::convertTypeToDict {mode serviceName node type root} {
    variable typeInfo
    variable mutableTypeInfo
    variable options

    ::log::log debug [list ::WS::Utils::convertTypeToDict $mode $serviceName $node $type $root]
    set typeDefInfo [dict get $typeInfo $mode $serviceName $type]
    ::log::log debug "\t type def = {$typeDefInfo}"
    set xns [dict get $typeDefInfo xns]
    if {[$node hasAttribute href]} {
        set node [GetReferenceNode $root [$node getAttribute href]]
    }
    ::log::log debug "\t XML of node is [$node asXML]"
    if {[info exists mutableTypeInfo([list $mode $serviceName $type])]} {
        set type [(*)[lindex mutableTypeInfo([list $mode $serviceName $type]) 0] $mode $serviceName $type $xns $node]
        set typeDefInfo [dict get $typeInfo $mode $serviceName $type]
        ::log::log debug "\t type def replaced with = {$typeDefInfo}"
    }
    set results {}
    #if {$options(parseInAttr)} {
    #    foreach attr [$node attributes] {
    #        if {[llength $attr] == 1} {
    #            dict set results $attr [$node getAttribute $attr]
    #        }
    #    }
    #}
    set partsList [dict keys [dict get $typeDefInfo definition]]
    ::log::log debug "\t partsList is {$partsList}"
    foreach partName $partsList {
        set partType [dict get $typeDefInfo definition $partName type]
        if {[string equal $partName *] && [string equal $partType *]} {
            ##
            ## Type infomation being handled dynamically for this part
            ##
            set savedTypeInfo $typeInfo
            parseDynamicType $mode $serviceName $node $type
            set tmp [convertTypeToDict $mode $serviceName $node $type $root]
            foreach partName [dict keys $tmp] {
                dict set results $partName [dict get $tmp $partName]
            }
            set typeInfo $savedTypeInfo
            continue
        }
        set partXns $xns
        catch {set partXns  [dict get $typeInfo $mode $serviceName $partType xns]}
        set typeInfoList [TypeInfo $mode $serviceName $partType]
        ::log::log debug "\tpartName $partName partType $partType xns $xns typeInfoList $typeInfoList"
        ##
        ## Try for fully qualified name
        ##
        ::log::log debug "Trying #1 [list $node selectNodes $partXns:$partName]"
        if {[catch {llength [set item [$node selectNodes $partXns:$partName]]} len] || ($len == 0)} {
            ::log::log debug "Trying #2 [list $node selectNodes $xns:$partName]"
            if {[catch {llength [set item [$node selectNodes $xns:$partName]]} len] || ($len == 0)} {
                ##
                ## Try for unqualified name
                ##
                ::log::log debug "Trying #3 [list $node selectNodes $partName]"
                if {[catch {llength [set item [$node selectNodes $partName]]} len] || ($len == 0)} {
                    ::log::log debug "Trying #4 -- search of children"
                    set item {}
                    set matchList [list $partXns:$partName  $xns:$partName $partName]
                    foreach childNode [$node childNodes] {
                        # From SOAP1.1 Spec:
                        #    Within an array value, element names are not significant
                        # for distinguishing accessors. Elements may have any name.
                        # Here we don't need check the element name, just simple check
                        # it's a element node
                        if { [$childNode nodeType] != "ELEMENT_NODE" } {
                            continue
                        }
                        lappend item $childNode
                    }
                    if {![string length $item]} {
                        ::log::log debug "\tSkipping"
                        continue
                    }
                }
            }
        }
        set origItemList $item
        set newItemList {}
        foreach item $origItemList {
            if {[$item hasAttribute href]} {
                set oldXML [$item asXML]
                set item [GetReferenceNode $root [$item getAttribute href]]
                ::log::log debug "\t\t Replacing: $oldXML"
                ::log::log debug "\t\t With: [$item asXML]"
            }
            lappend newItemList $item
        }
        set item $newItemList
        switch $typeInfoList {
            {0 0} {
                ##
                ## Simple non-array
                ##
                if {$options(parseInAttr)} {
                    foreach attr [$item attributes] {
                        if {[llength $attr] == 1} {
                            dict set results $partName $attr [$item getAttribute $attr]
                        }
                    }
                    dict set results $partName {} [$item asText]
                } else {
                    dict set results $partName [$item asText]
                }
            }
            {0 1} {
                ##
                ## Simple array
                ##
                set tmp {}
                foreach row $item {
                    if {$options(parseInAttr)} {
                        set rowList {}
                        foreach attr [$item attributes] {
                            if {[llength $attr] == 1} {
                                append rowList $attr [$row getAttribute $attr]
                            }
                        }
                        lappend rowList {} [$row asText]
                        lappend tmp $rowList
                    } else {
                        lappend tmp [$row asText]
                    }
                }
                dict set results $partName $tmp
            }
            {1 0} {
                ##
                ## Non-simple non-array
                ##
                if {$options(parseInAttr)} {
                    foreach attr [$item attributes] {
                        if {[llength $attr] == 1} {
                            dict set results $partName $attr [$item getAttribute $attr]
                        }
                    }
                    dict set results $partName {} [convertTypeToDict $mode $serviceName $item $partType $root]
                } else {
                    dict set results $partName [convertTypeToDict $mode $serviceName $item $partType $root]
                }
            }
            {1 1} {
                ##
                ## Non-simple array
                ##
                set partType [string trimright $partType {()}]
                set tmp [list]
                foreach row $item {
                    if {$options(parseInAttr)} {
                        set rowList {}
                        foreach attr [$item attributes] {
                            if {[llength $attr] == 1} {
                                append rowList $attr [$row getAttribute $attr]
                            }
                        }
                        lappend rowList {} [convertTypeToDict $mode $serviceName $row $partType $root]
                        lappend tmp $rowList
                    } else {
                        lappend tmp [convertTypeToDict $mode $serviceName $row $partType $root]
                    }
                }
                dict set results $partName $tmp
            }
        }
    }
    ::log::log debug [list Leaving ::WS::Utils::convertTypeToDict with $results]
    return $results
}

###########################################################################
#
# Private Procedure Header - as this procedure is modified, please be sure
#                            that you update this header block. Thanks.
#
#>>BEGIN PRIVATE<<
#
# Procedure Name : ::WS::Utils::GetReferenceNode
#
# Description : Get a reference node.
#
# Arguments :
#    root        - The root node of the document
#    root        - The root node of the document
#
# Returns : A node object.
#
# Side-Effects : None
#
# Exception Conditions : None
#
# Pre-requisite Conditions : None
#
# Original Author : Gerald W. Lester
#
#>>END PRIVATE<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  08/19/2008  G.Lester     Initial version
#
#
###########################################################################
proc ::WS::Utils::GetReferenceNode {root id} {
    set id [string trimleft $id {#}]
    set node [$root selectNodes -cache yes [format {//*[@id="%s"]} $id]]
    if {[$node hasAttribute href]} {
        set node [GetReferenceNode $root [$node getAttribute href]]
    }
    return $node
}

###########################################################################
#
# Private Procedure Header - as this procedure is modified, please be sure
#                            that you update this header block. Thanks.
#
#>>BEGIN PRIVATE<<
#
# Procedure Name : ::WS::Utils::convertDictToType
#
# Description : Convert a dictionary object into a XML DOM tree.
#
# Arguments :
#    mode        - The mode, Client or Server
#    service     - The service name the type is defined in
#    parent      - The parent node of the type.
#    doc         - The document
#    dict        - The dictionary to convert
#    type        - The name of the type
#
# Returns : None
#
# Side-Effects : None
#
# Exception Conditions : None
#
# Pre-requisite Conditions : None
#
# Original Author : Gerald W. Lester
#
#>>END PRIVATE<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  07/06/2006  G.Lester     Initial version
#
#
###########################################################################
proc ::WS::Utils::convertDictToType {mode service doc parent dict type} {
    ::log::log debug "Entering ::WS::Utils::convertDictToType $mode $service $doc $parent {$dict} $type"
    variable typeInfo
    variable simpleTypes
    variable options
    variable standardAttributes

    if {!$options(UseNS)} {
        return [::WS::Utils::convertDictToTypeNoNs $mode $service $doc $parent $dict $type]
    }

    set typeInfoList [TypeInfo $mode $service $type]
    if {[lindex $typeInfoList 0]} {
        set itemList [dict get $typeInfo $mode $service $type definition]
        set xns [dict get $typeInfo $mode $service $type xns]
    } else {
        set xns $simpleTypes($mode,$service,$type)
        set itemList [list $type {type string}]
    }
    if {[info exists mutableTypeInfo([list $mode $service $type])]} {
        set type [(*)[lindex mutableTypeInfo([list $mode $service $type]) 0] $mode $service $type $xns $dict]
        set typeInfoList [TypeInfo $mode $service $type]
        if {[lindex $typeInfoList 0]} {
            set itemList [dict get $typeInfo $mode $service $type definition]
            set xns [dict get $typeInfo $mode $service $type xns]
        } else {
            set xns $simpleTypes($mode,$service,$type)
            set itemList [list $type {type string}]
        }
    }
    ::log::log debug "\titemList is {$itemList} in $xns"
    set fieldList {}
    foreach {itemName itemDef} $itemList {
        lappend fieldList $itemName
        set itemType [dict get $itemDef type]
        ::log::log debug "\t\titemName = {$itemName} itemDef = {$itemDef} itemType ={$itemType}"
        set typeInfoList [TypeInfo $mode $service $itemType]
        if {![dict exists $dict $itemName]} {
            continue
        }
        set tmpInfo [GetServiceTypeDef $mode $service [string trimright $itemType {()}]]
        if {[dict exists $tmpInfo xns]} {
            set itemXns [dict get $tmpInfo xns]
        } else {
            set itemXns $xns
        }
        set attrList {}
        foreach key [dict keys $itemDef] {
            if {[lsearch -exact $standardAttributes $key] == -1} {
                lappend attrList $key [dict get $itemDef $key]
                ::log::log debug "key = {$key} standardAttributes = {$standardAttributes}"
            }
        }
        ::log::log debug "\t\titemName = {$itemName} itemDef = {$itemDef} typeInfoList = {$typeInfoList} itemXns = {$itemXns} tmpInfo = {$tmpInfo} attrList = {$attrList}"
        switch $typeInfoList {
            {0 0} {
                ##
                ## Simple non-array
                ##
                $parent appendChild [$doc createElement $itemXns:$itemName retNode]
                if {$options(genOutAttr)} {
                    set dictList [dict keys [dict get $dict $itemName]]
                    foreach attr [lindex [::struct::set intersect3 $standardAttributes $dictList] end] {
                        if {[string equal $attr  {}]} {
                            lappend attrList $attr [dict get $dict $itemName $attr]
                        } else {
                            set resultValue [dict get $dict $itemName $attr]
                        }
                    }
                } else {
                    set resultValue [dict get $dict $itemName]
                }
                $retNode appendChild [$doc createTextNode $resultValue]
                if {[llength $attrList]} {
                    ::WS::Utils::setAttr $retNode $attrList
                }
            }
            {0 1} {
                ##
                ## Simple array
                ##
                set dataList [dict get $dict $itemName]
                foreach row $dataList {
                    $parent appendChild [$doc createElement $itemXns:$itemName retNode]
                    if {$options(genOutAttr)} {
                        set dictList [dict keys $row]
                        foreach attr [lindex [::struct::set intersect3 $standardAttributes $dictList] end] {
                            if {[string equal $attr  {}]} {
                                lappend attrList $attr [dict get $row $attr]
                            } else {
                                set resultValue [dict get $row $attr]
                            }
                        }
                    } else {
                        set resultValue $row
                    }
                    $retNode appendChild [$doc createTextNode $resultValue]
                    if {[llength $attrList]} {
                        ::WS::Utils::setAttr $retNode $attrList
                    }
                }
            }
            {1 0} {
                ##
                ## Non-simple non-array
                ##
                $parent appendChild [$doc createElement $itemXns:$itemName retNode]
                if {$options(genOutAttr)} {
                    set dictList [dict keys [dict get $dict $itemName]]
                    foreach attr [lindex [::struct::set intersect3 $standardAttributes $dictList] end] {
                        if {[string equal $attr  {}]} {
                            lappend attrList $attr [dict get $dict $itemName $attr]
                        } else {
                            set resultValue [dict get $dict $itemName $attr]
                        }
                    }
                } else {
                    set resultValue [dict get $dict $itemName]
                }
                convertDictToType $mode $service $doc $retNode $resultValue $itemType
                if {[llength $attrList]} {
                    ::WS::Utils::setAttr $retNode $attrList
                }
            }
            {1 1} {
                ##
                ## Non-simple array
                ##
                set dataList [dict get $dict $itemName]
                set tmpType [string trimright $itemType ()]
                foreach row $dataList {
                    $parent appendChild [$doc createElement $itemXns:$itemName retNode]
                    if {$options(genOutAttr)} {
                        set dictList [dict keys $row]
                        foreach attr [lindex [::struct::set intersect3 $standardAttributes $dictList] end] {
                            if {[string equal $attr  {}]} {
                                lappend attrList $attr [dict get $row $attr]
                            } else {
                                set resultValue [dict get $row $attr]
                            }
                        }
                    } else {
                        set resultValue $row
                    }
                    convertDictToType $mode $service $doc $retNode $resultValue $tmpType
                    if {[llength $attrList]} {
                        ::WS::Utils::setAttr $retNode $attrList
                    }
                }
            }
        }
        #if {$options(genOutAttr)} {
        #    set dictList [dict keys $dict]
        #    foreach attr [lindex [::struct::set intersect3 $fieldList $dictList] end] {
        #        $parent setAttribute $attr [dict get $dict $attr]
        #    }
        #}
    }
    return;
}

###########################################################################
#
# Private Procedure Header - as this procedure is modified, please be sure
#                            that you update this header block. Thanks.
#
#>>BEGIN PRIVATE<<
#
# Procedure Name : ::WS::Utils::convertDictToTypeNoNs
#
# Description : Convert a dictionary object into a XML DOM tree.
#
# Arguments :
#    mode        - The mode, Client or Server
#    service     - The service name the type is defined in
#    parent      - The parent node of the type.
#    dict        - The dictionary to convert
#    type        - The name of the type
#
# Returns : None
#
# Side-Effects : None
#
# Exception Conditions : None
#
# Pre-requisite Conditions : None
#
# Original Author : Gerald W. Lester
#
#>>END PRIVATE<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  07/06/2006  G.Lester     Initial version
#
#
###########################################################################
proc ::WS::Utils::convertDictToTypeNoNs {mode service doc parent dict type} {
    ::log::log debug "Entering ::WS::Utils::convertDictToTypeNoNs $mode $service $doc $parent {$dict} $type"
    variable typeInfo
    variable simpleTypes

    set typeInfoList [TypeInfo $mode $service $type]
    if {[lindex $typeInfoList 0]} {
        set itemList [dict get $typeInfo $mode $service $type definition]
        set xns [dict get $typeInfo $mode $service $type xns]
    } else {
        set xns $simpleTypes($mode,$service,$type)
        set itemList [list $type {type string}]
    }
    ::log::log debug "\titemList is {$itemList}"
    foreach {itemName itemDef} $itemList {
        ::log::log debug "\t\titemName = {$itemName} itemDef = {$itemDef}"
        set itemType [dict get $itemDef type]
        set typeInfoList [TypeInfo $mode $service $itemType]
        if {![dict exists $dict $itemName]} {
            continue
        }
        set attrList {}
        foreach key [dict keys $itemDef] {
            if {[lsearch -exact $standardAttributes $key] == -1} {
                lappend attrList $key [dict get $itemDef $key]
                ::log::log debug "key = {$key} standardAttributes = {$standardAttributes}"
            }
        }
        ::log::log debug "\t\titemName = {$itemName} itemDef = {$itemDef} typeInfoList = {$typeInfoList}"
        switch $typeInfoList {
            {0 0} {
                ##
                ## Simple non-array
                ##
                $parent appendChild [$doc createElement $itemName retNode]
                if {$options(genOutAttr)} {
                    set dictList [dict keys [dict get $dict $itemName]]
                    foreach attr [lindex [::struct::set intersect3 $standardAttributes $dictList] end] {
                        if {[string equal $attr  {}]} {
                            lappend attrList $attr [dict get $dict $itemName $attr]
                        } else {
                            set resultValue [dict get $dict $itemName $attr]
                        }
                    }
                } else {
                    set resultValue [dict get $dict $itemName]
                }
                $retNode appendChild [$doc createTextNode $resultValue]
                if {[llength $attrList]} {
                    ::WS::Utils::setAttr $retNode $attrList
                }
            }
            {0 1} {
                ##
                ## Simple array
                ##
                set dataList [dict get $dict $itemName]
                foreach row $dataList {
                    $parent appendChild [$doc createElement $itemName retNode]
                    if {$options(genOutAttr)} {
                        set dictList [dict keys $row]
                        foreach attr [lindex [::struct::set intersect3 $standardAttributes $dictList] end] {
                            if {[string equal $attr  {}]} {
                                lappend attrList $attr [dict get $row $attr]
                            } else {
                                set resultValue [dict get $row $attr]
                            }
                        }
                    } else {
                        set resultValue $row
                    }
                    $retNode appendChild [$doc createTextNode $resultValue]
                    if {[llength $attrList]} {
                        ::WS::Utils::setAttr $retNode $attrList
                    }
                }
            }
            {1 0} {
                ##
                ## Non-simple non-array
                ##
                $parent appendChild [$doc createElement $itemName retnode]
                if {$options(genOutAttr)} {
                    set dictList [dict keys [dict get $dict $itemName]]
                    foreach attr [lindex [::struct::set intersect3 $standardAttributes $dictList] end] {
                        if {[string equal $attr  {}]} {
                            lappend attrList $attr [dict get $dict $itemName $attr]
                        } else {
                            set resultValue [dict get $dict $itemName $attr]
                        }
                    }
                } else {
                    set resultValue [dict get $dict $itemName]
                }
                if {[llength $attrList]} {
                    ::WS::Utils::setAttr $retNode $attrList
                }
                convertDictToTypeNoNs $mode $service $doc $retnode $resultValue $itemType
            }
            {1 1} {
                ##
                ## Non-simple array
                ##
                set dataList [dict get $dict $itemName]
                set tmpType [string trimright $itemType ()]
                foreach row $dataList {
                    $parent appendChild [$doc createElement $itemName retnode]
                    if {$options(genOutAttr)} {
                        set dictList [dict keys $row]
                        foreach attr [lindex [::struct::set intersect3 $standardAttributes $dictList] end] {
                            if {[string equal $attr  {}]} {
                                lappend attrList $attr [dict get $row $attr]
                            } else {
                                set resultValue [dict get $row $attr]
                            }
                        }
                    } else {
                        set resultValue $row
                    }
                    if {[llength $attrList]} {
                        ::WS::Utils::setAttr $retNode $attrList
                    }
                    convertDictToTypeNoNs $mode $service $doc $retnode $resultValue $tmpType
                }
            }
        }
    }
    return;
}

###########################################################################
#
# Private Procedure Header - as this procedure is modified, please be sure
#                            that you update this header block. Thanks.
#
#>>BEGIN PRIVATE<<
#
# Procedure Name : ::WS::Utils::convertDictToEncodedType
#
# Description : Convert a dictionary object into a XML DOM tree with type
#               enconding.
#
# Arguments :
#    mode        - The mode, Client or Server
#    service     - The service name the type is defined in
#    parent      - The parent node of the type.
#    dict        - The dictionary to convert
#    type        - The name of the type
#
# Returns : None
#
# Side-Effects : None
#
# Exception Conditions : None
#
# Pre-requisite Conditions : None
#
# Original Author : Gerald W. Lester
#
#>>END PRIVATE<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  07/06/2006  G.Lester     Initial version
#
#
###########################################################################
proc ::WS::Utils::convertDictToEncodedType {mode service doc parent dict type} {
    ::log::log debug "Entering ::WS::Utils::convertDictToType $mode $service $doc $parent {$dict} $type"
    variable typeInfo

    set itemList [dict get $typeInfo $mode $service $type definition]
    set xns [dict get $typeInfo $mode $service $type xns]
    ::log::log debug "\titemList is {$itemList}"
    foreach {itemName itemDef} $itemList {
        set itemType [dict get $itemList $itemName type]
        set typeInfoList [TypeInfo $mode $service $itemType]
        if {![dict exists $dict $itemName]} {
            continue
        }
        switch $typeInfoList {
            {0 0} {
                ##
                ## Simple non-array
                ##
                $parent appendChild [$doc createElement $xns:$itemName retNode]
                $retNode setAttribute xsi:type xs:$itemType
                set resultValue [dict get $dict $itemName]
                $retNode appendChild [$doc createTextNode $resultValue]
            }
            {0 1} {
                ##
                ## Simple array
                ##
                set dataList [dict get $dict $itemName]
                set tmpType [string trimright $itemType {()}]
                foreach resultValue $dataList {
                    $parent appendChild [$doc createElement $xns:$itemName retNode]
                    $retNode setAttribute xsi:type xs:$itemType
                    set resultValue [dict get $dict $itemName]
                    $retNode appendChild [$doc createTextNode $resultValue]
                }
            }
            {1 0} {
                ##
                ## Non-simple non-array
                ##
                $parent appendChild [$doc createElement $xns:$itemName retNode]
                $retNode setAttribute xsi:type xs:$itemType
                                 convertDictToEncodedType $mode $service $doc $retNode [dict get $dict $itemName] $itemType
            }
            {1 1} {
                ##
                ## Non-simple array
                ##
                set dataList [dict get $dict $itemName]
                set tmpType [string trimright $itemType ()]
                foreach item $dataList {
                    $parent appendChild [$doc createElement $xns:$itemName retNode]
                    $retNode setAttribute xsi:type xs:$itemType
                    convertDictToEncodedType $mode $service $doc $retNode $item $tmpType
                }
            }
        }
    }
    return;
}

###########################################################################
#
# Private Procedure Header - as this procedure is modified, please be sure
#                            that you update this header block. Thanks.
#
#>>BEGIN PRIVATE<<
#
# Procedure Name : ::WS::Utils::parseDynamicType
#
# Description : Parse the Xschme for a dynamically typed part.
#
# Arguments :
#    mode        - The mode, Client or Server
#    serviceName - The service name the type is defined in
#    node        - The base node for the type.
#    type        - The name of the type
#
# Returns : A dictionary object for a given type.
#
# Side-Effects : Type deginitions added
#
# Exception Conditions : None
#
# Pre-requisite Conditions : None
#
# Original Author : Gerald W. Lester
#
#>>END PRIVATE<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  07/06/2006  G.Lester     Initial version
#
#
###########################################################################
proc ::WS::Utils::parseDynamicType {mode serviceName node type} {
    variable typeInfo
    variable nsList

    ::log::log debug [list ::WS::Utils::parseDynamicType $mode $serviceName $node $type]

    foreach child [$node childNodes] {
        ::log::log debug "\t Child $child is [$child nodeName]"
    }

    ##
    ## Get type being defined
    ##
    set schemeNode [$node selectNodes -namespaces $nsList s:schema]
    set newTypeNode [$node selectNodes -namespaces $nsList  s:schema/s:element]
    set newTypeName [lindex [split [$newTypeNode getAttribute name] :] end]

    ##
    ## Get sibling node to scheme and add tempory type definitions
    ##
    ## type == sibing of temp type
    ## temp_type == newType of newType
    ##
    set tnsCountVar [llength [dict get $::WS::Client::serviceArr($serviceName) targetNamespace]]
    set tns tnx$tnsCountVar
    set dataNode {}
    $schemeNode nextSibling dataNode
    if {![info exists dataNode] || ![string length $dataNode]} {
        $schemeNode previousSibling dataNode
    }
    set dataNodeNameList [split [$dataNode nodeName] :]
    set dataTnsName [lindex $dataNodeNameList 0]
    set dataNodeName [lindex $dataNodeNameList end]
    set tempTypeName 1_temp_type
    dict set typeInfo $mode $serviceName $tempTypeName [list  xns $tns definition [list $newTypeName [list type $newTypeName comment {}]]]
    dict set typeInfo $mode $serviceName $type [list xns $dataTnsName definition [list $dataNodeName [list type $tempTypeName comment {}]]]

    ##
    ## Parse the Scheme --gwl
    ##
    parseScheme $mode {} $schemeNode $serviceName typeInfo tnsCountVar

    ##
    ## All done
    ##
    return;
}

###########################################################################
#
# Private Procedure Header - as this procedure is modified, please be sure
#                            that you update this header block. Thanks.
#
#>>BEGIN PRIVATE<<
#
# Procedure Name : ::WS::Utils::parseScheme
#
# Description : Parse the types for a service from a Schema into
#               our internal representation
#
# Arguments :
#    mode        - The mode, Client or Server
#    SchemaNode       - The top node of the Schema
#    serviceNode    - The DOM node for the service.
#    serviceInfoVar - The name of the dictionary containing the partially
#                     parsed service.
#    tnsCountVar -- variable name holding count of tns so far
#
# Returns : Nothing
#
# Side-Effects : Defines mode types for the service as specified by the Schema
#
# Exception Conditions : None
#
# Pre-requisite Conditions : None
#
# Original Author : Gerald W. Lester
#
#>>END PRIVATE<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  08/06/2006  G.Lester     Initial version
#
#
###########################################################################
proc ::WS::Utils::parseScheme {mode baseUrl schemaNode serviceName serviceInfoVar tnsCountVar} {
    ::log::log debug "Entering :WS::Utils::parseScheme $mode $baseUrl $schemaNode $serviceName $serviceInfoVar $tnsCountVar"

    upvar $tnsCountVar tnsCount
    upvar $serviceInfoVar serviceInfo
    variable currentSchema
    variable nsList
    variable options

    #if {[dict exists $serviceInfo targetNamespace]} {
    #    foreach pair [dict get $serviceInfo targetNamespace] {
    #        if {[string equal $baseUrl [lindex $pair 1]]} {
    #            ::log::log debug "\t Already definec"
    #            return
    #        }
    #    }
    #}
    set currentSchema $schemaNode
    if {[$schemaNode hasAttribute targetNamespace]} {
        set xns [$schemaNode getAttribute targetNamespace]
    } else {
        set xns $baseUrl
    }
    set tns [format {tns%d} [incr tnsCount]]
    dict lappend serviceInfo targetNamespace [list $tns $xns]
    ::log::log debug "@3 TNS count for $baseUrl is $tnsCount {$tns}"

    ##
    ## Process Imports
    ##
    foreach element [$schemaNode selectNodes -namespaces $nsList s:import] {
        ::log::log debug "\tprocessing $element"
        if {[catch {processImport $mode $baseUrl $element $serviceName serviceInfo tnsCount} msg]} {
            switch -exact -- $options(StrictMode) {
                debug -
                warning {
                    log::log $options(StrictMode) "Could not parse:\n [$element asXML]"
                    log::log $options(StrictMode) "\t error was: $msg"
                }
                error -
                default {
                    set errorCode $::errorCode
                    set errorInfo $::errorInfo
                    log::log error "Could not parse:\n [$element asXML]"
                    log::log error "\t error was: $msg"
                    return \
                        -code error \
                        -errorcode $errorCode \
                        -errorinfo $errorInfo \
                        $msg
                }
            }
        }
    }

    ::log::log debug  "Parsing Element types"
    foreach element [$schemaNode selectNodes -namespaces $nsList s:element] {
        ::log::log debug "\tprocessing $element"
        if {[catch {parseElementalType $mode serviceInfo $serviceName $element $tns} msg]} {
            switch -exact -- $options(StrictMode) {
                debug -
                warning {
                    log::log $options(StrictMode) "Could not parse:\n [$element asXML]"
                    log::log $options(StrictMode) "\t error was: $msg"
                }
                error -
                default {
                    set errorCode $::errorCode
                    set errorInfo $::errorInfo
                    log::log error "Could not parse:\n [$element asXML]"
                    log::log error "\t error was: $msg"
                    return \
                        -code error \
                        -errorcode $errorCode \
                        -errorinfo $errorInfo \
                        $msg
                }
            }
        }
    }

    ::log::log debug  "Parsing Attribute types"
    foreach element [$schemaNode selectNodes -namespaces $nsList s:attribute] {
        ::log::log debug "\tprocessing $element"
        if {[catch {parseElementalType $mode serviceInfo $serviceName $element $tns} msg]} {
            switch -exact -- $options(StrictMode) {
                debug -
                warning {
                    log::log $options(StrictMode) "Could not parse:\n [$element asXML]"
                    log::log $options(StrictMode) "\t error was: $msg"
                }
                error -
                default {
                    set errorCode $::errorCode
                    set errorInfo $::errorInfo
                    log::log error "Could not parse:\n [$element asXML]"
                    log::log error "\t error was: $msg"
                    return \
                        -code error \
                        -errorcode $errorCode \
                        -errorinfo $errorInfo \
                        $msg
                }
            }
        }
    }

    ::log::log debug "Parsing Simple types"
    foreach element [$schemaNode selectNodes -namespaces $nsList s:simpleType] {
        ::log::log debug "\tprocessing $element"
        if {[catch {parseSimpleType $mode serviceInfo $serviceName $element $tns} msg]} {
            switch -exact -- $options(StrictMode) {
                debug -
                warning {
                    log::log $options(StrictMode) "Could not parse:\n [$element asXML]"
                    log::log $options(StrictMode) "\t error was: $msg"
                }
                error -
                default {
                    set errorCode $::errorCode
                    set errorInfo $::errorInfo
                    log::log error "Could not parse:\n [$element asXML]"
                    log::log error "\t error was: $msg"
                    return \
                        -code error \
                        -errorcode $errorCode \
                        -errorinfo $errorInfo \
                        $msg
                }
            }
        }
    }

    ::log::log debug  "Parsing Complex types"
    foreach element [$schemaNode selectNodes -namespaces $nsList s:complexType] {
        ::log::log debug "\tprocessing $element"
        if {[catch {parseComplexType $mode serviceInfo $serviceName $element $tns} msg]} {
            switch -exact -- $options(StrictMode) {
                debug -
                warning {
                    log::log $options(StrictMode) "Could not parse:\n [$element asXML]"
                    log::log $options(StrictMode) "\t error was: $msg"
                }
                error -
                default {
                    set errorCode $::errorCode
                    set errorInfo $::errorInfo
                    log::log error "Could not parse:\n [$element asXML]"
                    log::log error "\t error was: $msg"
                    return \
                        -code error \
                        -errorcode $errorCode \
                        -errorinfo $errorInfo \
                        $msg
                }
            }
        }
    }
}

###########################################################################
#
# Private Procedure Header - as this procedure is modified, please be sure
#                            that you update this header block. Thanks.
#
#>>BEGIN PRIVATE<<
#
# Procedure Name : ::WS::Utils::processImport
#
# Description : Parse the bindings for a service from a Schema into our
#               internal representation
#
# Arguments :
#    baseUrl        - The url of the importing node
#    importNode     - The node to import
#    serviceName    - The name service.
#    serviceInfoVar - The name of the dictionary containing the partially
#                     parsed service.
#    tnsCountVar    - The name of the variable containing the count of the
#                     namespace.
#
# Returns : Nothing
#
# Side-Effects : Defines mode types for the service as specified by the Schema
#
# Exception Conditions : None
#
# Pre-requisite Conditions : None
#
# Original Author : Gerald W. Lester
#
#>>END PRIVATE<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  08/06/2006  G.Lester     Initial version
#
#
###########################################################################
proc ::WS::Utils::processImport {mode baseUrl importNode serviceName serviceInfoVar tnsCountVar} {
    upvar $serviceInfoVar serviceInfo
    upvar $tnsCountVar tnsCount
    variable currentSchema
    variable importedXref

    ::log::log debug "Entering [info level 0]"
    ##
    ## Get the xml
    ##
    set attrName schemaLocation
    if {![$importNode hasAttribute $attrName]} {
        set attrName location
        if {![$importNode hasAttribute $attrName]} {
            set attrName namespace
            if {![$importNode hasAttribute $attrName]} {
                ::log::log debug "\t No schema location, existing"
                set xml [$importNode asXML]
                return \
                    -code error \
                    -errorcode [list WS CLIENT MISSCHLOC $xml] \
                    "Missing Schema Location in '$xml'"
            }
        }
    }
    set url [::uri::resolve $baseUrl  [$importNode getAttribute $attrName]]
    ::log::log debug "\t Importing {$url}"
    ##
    ## Short-circuit infinite loop on inports
    ##
    if { [info exists importedXref($mode,$serviceName,$url)] } {
        ::log::log debug "$mode,$serviceName,$url was already imported: $importedXref($mode,$serviceName,$url)"
        return
    }
    set importedXref($mode,$serviceName,$url) [list $mode $serviceName $tnsCount]
    switch [dict get [::uri::split $url] scheme] {
        file {
            upvar #0 [::uri::geturl $url] token
            set xml $token(data)
            unset token
            ProcessImportXml $mode $baseUrl $xml $serviceName $serviceInfoVar $tnsCountVar
        }
        http {
            set ncode -1
            catch {
                set token [::http::geturl $url]
                ::http::wait $token
                set ncode [::http::ncode $token]
                set xml [::http::data $token]
                ::http::cleanup $token
                ProcessImportXml $mode $baseUrl $xml $serviceName $serviceInfoVar $tnsCountVar
            }
            if {$ncode != 200} {
                return \
                    -code error \
                    -errorcode [list WS CLIENT HTTPFAIL $url $ncode] \
                    "HTTP get of import file failed '$url'"
            }
        }
        default {
            return \
                -code error \
                -errorcode [list WS CLIENT UNKURLTYP $url] \
                "Unknown URL type '$url'"
        }
    }
}


###########################################################################
#
# Private Procedure Header - as this procedure is modified, please be sure
#                            that you update this header block. Thanks.
#
#>>BEGIN PRIVATE<<
#
# Procedure Name : ::WS::Utils::parseComplexType
#
# Description : Parse a complex type declaration from the Schema into our
#               internal representation
#
# Arguments :
#    dcitVar            - The name of the results dictionary
#    servcieName        - The service name this type belongs to
#    node               - The root node of the type definition
#    tns                - Namespace for this type
#
# Returns : Nothing
#
# Side-Effects : Defines mode type as specified by the Schema
#
# Exception Conditions : None
#
# Pre-requisite Conditions : None
#
# Original Author : Gerald W. Lester
#
#>>END PRIVATE<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  07/06/2006  G.Lester     Initial version
#
#
###########################################################################
proc ::WS::Utils::parseComplexType {mode dictVar serviceName node tns} {
    upvar $dictVar results
    variable currentSchema
    variable nsList

    ::log::log debug "Entering [info level 0]"

    set typeName [$node getAttribute name]
    set partList {}
    set nodeFound 0
    array set attrArr {}
    set comment {}
    catch {
        set commentNodeList [$middleNode selectNodes -namespaces $nsList s:annotation]
        set commentNode [lindex $commentNodeList 0]
        set comment [string trim [$commentNode asText]]
    }
    foreach middleNode [$node childNodes] {
        set middle [$middleNode localName]
        ::log::log debug "Complex Type is $typeName, middle is $middle"
        #puts "Complex Type is $typeName, middle is $middle"
        switch $middle {
            annotation {
                ##
                ## Do nothing
                ##
                continue
            }
            element -
            attribute {
                set nodeFound 1
                set partName [$middleNode getAttribute name]
                set partType [lindex [split [$middleNode getAttribute type string:string] {:}] end]
                set partMax [$middleNode getAttribute maxOccurs 1]
                if {[string equal $partMax 1]} {
                    lappend partList $partName [list type $partType comment $comment]
                } else {
                    lappend partList $partName [list type [string trimright ${partType} {()}]() comment $comment]
                }
            }
            extension {
                set baseName [lindex [split [$middleNode getAttribute base] {:}] end]
                set tmp [partList $mode $middleNode $serviceName results $tns]
                if {[llength $tmp]} {
                    set nodeFound 1
                    set partList [concat $partList $tmp]
                }
            }
            choice -
            sequence -
            all {
                set elementList [$middleNode selectNodes -namespaces $nsList s:element]
                set partMax [$middleNode getAttribute maxOccurs 1]
                set tmp [partList $mode $middleNode $serviceName results $tns $partMax]
                if {[llength $tmp]} {
                    ::log::log debug "\tadding {$tmp} to partslist"
                    set nodeFound 1
                    set partList [concat $partList $tmp]
                } else {
                    ::WS::Utils::ServiceSimpleTypeDef $mode $serviceName $typeName [list base string comment $comment] $tns
                    return
                }
            }
            complexType {
                $middleNode setAttribute name $typeName
                parseComplexType $mode results $serviceName $middleNode $tns
            }
            simpleContent -
            complexContent {
                set contentType [[$middleNode childNodes] localName]
                switch $contentType {
                    restriction {
                        set nodeFound 1
                        set restriction [$middleNode selectNodes -namespaces $nsList s:restriction]
                        catch {
                            set element [$middleNode selectNodes -namespaces $nsList s:restriction/s:attribute]
                            set typeInfoList [list baseType [$restriction getAttribute base]]
                            array unset attrArr
                            foreach attr [$element attributes] {
                                if {[llength $attr] > 1} {
                                    set name [lindex $attr 0]
                                    set ref [lindex $attr 1]:[lindex $attr 0]
                                } else {
                                    set name $attr
                                    set ref $attr
                                }
                                catch {set attrArr($name) [$element getAttribute $ref]}
                            }
                            set partName item
                            set partType [lindex [split $attrArr(arrayType) {:}] end]
                            set partType [string map {{[]} {()}} $partType]
                            lappend partList $partName [list type [string trimright ${partType} {()}]() comment $comment]
                            set nodeFound 1
                        }
                    }
                    extension {
                        set tmp [partList $mode $middleNode $serviceName results $tns]
                        if {[llength $tmp]} {
                        set nodeFound 1
                            set partList [concat $partList $tmp]
                        }
                    }
                }
            }
            restriction {
                parseSimpleType $mode results $serviceName $node $tns
                return
            }
            default {
                parseElementalType $mode results $serviceName $node $tns
                return
            }
        }
    }
    if {[llength $partList]} {
        dict set results types $typeName $partList
        ::WS::Utils::ServiceTypeDef $mode $serviceName $typeName $partList $tns
    } elseif {!$nodeFound} {
        #puts "Defined $typeName as simple type"
        ::WS::Utils::ServiceSimpleTypeDef $mode $serviceName $typeName [list base string comment {}] $tns
    } else {
        set xml [string trim [$node asXML]]
        return \
            -code error \
            -errorcode [list WS $mode BADCPXTYPDEF [list $typeName $xml]] \
            "Bad complex type definition for '$typeName' :: '$xml'"
    }
}

###########################################################################
#
# Private Procedure Header - as this procedure is modified, please be sure
#                            that you update this header block. Thanks.
#
#>>BEGIN PRIVATE<<
#
# Procedure Name : ::WS::Utils::partList
#
# Description : Prase the list of parts of a type definition from the Schema into our
#               internal representation
#
# Arguments :
#    dcitVar            - The name of the results dictionary
#    servcieName        - The service name this type belongs to
#    node               - The root node of the type definition
#    tns                - Namespace for this type
#
# Returns : Nothing
#
# Side-Effects : Defines mode type as specified by the Schema
#
# Exception Conditions : None
#
# Pre-requisite Conditions : None
#
# Original Author : Gerald W. Lester
#
#>>END PRIVATE<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  07/06/2006  G.Lester     Initial version
#
#
###########################################################################
proc ::WS::Utils::partList {mode node serviceName dictVar tns {occurs {}}} {
    variable currentSchema
    variable nsList
    upvar $dictVar results

    set partList {}
    set middle [$node localName]
    ::log::log debug "Entering [info level 0] -- for $middle"
    switch $middle {
        element -
        attribute {
            catch {
                set partName [$node getAttribute name]
                set partType [lindex [split [$node getAttribute type string:string] {:}] end]
                set partMax [$node getAttribute maxOccurs 1]
                if {[string equal $partMax 1]} {
                    set partList [list $partName [list type $partType comment {}]]
                } else {
                    set partList [list $partName [list type [string trimright ${partType} {()}]() comment {}]]
                }
            }
        }
        extension {
            set baseName [lindex [split [$node getAttribute base] {:}] end]
            #puts "base name $baseName"
            if {[lindex [TypeInfo Client $serviceName $baseName] 0]} {
                if {[catch {::WS::Utils::GetServiceTypeDef Client $serviceName $baseName}]} {
                    set baseQuery [format {child::*[attribute::name='%s']} $baseName]
                    set baseNode [$currentSchema selectNodes $baseQuery]
                    #puts "$baseQuery gave {$baseNode}"
                    set baseNodeType [$baseNode localName]
                    switch $baseNodeType {
                        complexType {
                            parseComplexType $mode serviceInfo $serviceName $baseNode $tns
                        }
                        element {
                            parseElementalType $mode serviceInfo $serviceName $baseNode $tns
                        }
                        simpleType {
                            parseSimpleType $mode serviceInfo $serviceName $baseNode $tns
                        }
                    }
                }
                set baseInfo [GetServiceTypeDef $mode $serviceName $baseName]
                catch {set partList [concat $partList [dict get $baseInfo definition]]}
            }
            foreach elementNode [$node childNodes] {
                set tmp [partList $mode $elementNode $serviceName results $tns]
                if {[llength $tmp]} {
                    set partList [concat $partList $tmp]
                }
            }
        }
        choice -
        sequence -
        all {
            set elementList [$node selectNodes -namespaces $nsList s:element]
            set elementsFound 0
            ::log::log debug "\telement list is {$elementList}"
            foreach element $elementList {
                ::log::log debug "\t\tprocessing $element ([$element nodeName])"
                set comment {}
                if {[catch {
                    set elementsFound 1
                    set attrName name
                    set isRef 0
                    if {![$element hasAttribute name]} {
                        set attrName ref
                        set isRef 1
                    }
                    set partName [$element getAttribute $attrName]
                    if {$isRef} {
                        set partType [dict get [::WS::Utils::GetServiceTypeDef $mode $serviceName $partName] definition $partName type]
                    } else {
                        ##
                        ## See if really a complex definition
                        ##
                        if {[$element hasChildNodes]} {
                            set isComplex 0
                            foreach child [$element childNodes] {
                                if {[string equal [$child localName] {annotation}]} {
                                    set comment [string trim [$child asText]]
                                } else {
                                    set isComplex 1
                                }
                            }
                            if {$isComplex} {
                                set partType $partName
                                parseComplexType $mode results $serviceName $element $tns
                            } else {
                                set partType [lindex [split [$element getAttribute type string:string] {:}] end]
                            }
                        } else {
                            set partType [lindex [split [$element getAttribute type string:string] {:}] end]
                        }
                    }
                    if {[string length $occurs]} {
                        set partMax [$element getAttribute maxOccurs 1]
                        if {$partMax < $occurs} {
                            set partMax $occurs
                        }
                    } else {
                        set partMax [$element getAttribute maxOccurs 1]
                    }
                    if {[string equal $partMax 1]} {
                        lappend partList $partName [list type $partType comment $comment]
                    } else {
                        lappend partList $partName [list type [string trimright ${partType} {()}]() comment $comment]
                    }
                } msg]} {
                        ::log::log error "\tError processing {$msg} for [$element asXML]"
                }
            }
            if {!$elementsFound} {
                return
            }
        }
        complexContent {
            set contentType [[$node childNodes] localName]
            switch $contentType {
                restriction {
                    set restriction [$node selectNodes -namespaces $nsList s:restriction]
                    set element [$node selectNodes -namespaces $nsList s:restriction/s:attribute]
                    set typeInfoList [list baseType [$restriction getAttribute base]]
                    array unset attrArr
                    foreach attr [$element attributes] {
                        if {[llength $attr] > 1} {
                            set name [lindex $attr 0]
                            set ref [lindex $attr 1]:[lindex $attr 0]
                        } else {
                            set name $attr
                            set ref $attr
                        }
                        catch {set attrArr($name) [$element getAttribute $ref]}
                    }
                    set partName item
                    set partType [lindex [split $attrArr(arrayType) {:}] end]
                    set partType [string map {{[]} {()}} $partType]
                    set partList [list $partName [list type [string trimright ${partType} {()}]() comment {}]]
                }
                extension {
                    set extension [$node selectNodes -namespaces $nsList s:extension]
                    set partList [partList $mode $extension $serviceName results $tns]
                }
            }
        }
        simpleContent {
            foreach elementNode [$node childNodes] {
                set tmp [partList $mode $elementNode $serviceName results $tns]
                if {[llength $tmp]} {
                    set partList [concat $partList $tmp]
                }
            }
        }
        restriction {
            parseSimpleType $mode results $serviceName $node $tns
            return
        }
        default {
            parseElementalType $mode results $serviceName $node $tns
            return
        }
    }
    return $partList
}

###########################################################################
#
# Private Procedure Header - as this procedure is modified, please be sure
#                            that you update this header block. Thanks.
#
#>>BEGIN PRIVATE<<
#
# Procedure Name : ::WS::Utils::parseElementalType
#
# Description : Parse an elemental type declaration from the Schema into our
#               internal representation
#
# Arguments :
#    dcitVar            - The name of the results dictionary
#    servcieName        - The service name this type belongs to
#    node               - The root node of the type definition
#    tns                - Namespace for this type
#
# Returns : Nothing
#
# Side-Effects : Defines mode type as specified by the Schema
#
# Exception Conditions : None
#
# Pre-requisite Conditions : None
#
# Original Author : Gerald W. Lester
#
#>>END PRIVATE<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  07/06/2006  G.Lester     Initial version
#
#
###########################################################################
proc ::WS::Utils::parseElementalType {mode dictVar serviceName node tns} {

    upvar $dictVar results
    variable importedXref
    variable nsList

    ::log::log debug "Entering [info level 0]"

    set attributeName name
    if {![$node hasAttribute $attributeName]} {
        set attributeName ref
    }
    set typeName [$node getAttribute $attributeName]
    set typeType ""
    if {[$node hasAttribute type]} {
            set typeType [$node getAttribute type]
    }
    ::log::log debug "Elemental Type is $typeName"
    set partList {}
    set elements [$node selectNodes -namespaces $nsList s:complexType/s:sequence/s:element]
    ::log::log debug "\t element list is {$elements}"
    foreach element $elements {
        ::log::log debug "\t\t Processing element {[$element nodeName]}"
        set elementsFound 1
        set typeAttribute ""
        if {[$element hasAttribute ref]} {
            ::log::log debug "\t\t has a ref of {[$element getAttribute ref]}"
            set refTypeInfo [split [$element getAttribute ref] {:}]
            set refNS [lindex $refTypeInfo 0]
            if {[string equal $refNS {}]} {
                set refType [lindex $refTypeInfo 1]
                set namespaceList [$element selectNodes namespace::*]
                set index [lsearch -glob $namespaceList "xmlns:$refNS *"]
                set url [lindex $namespaceList $index 1]
                ::log::log debug "\t\t reference is {$refNS} {$refType} {$url}"
                if {![info exists importedXref($mode,$serviceName,$url)]} {
                    return \
                        -code error \
                        -errorcode [list WS CLIENT NOTIMP $url] \
                        "Schema not imported: {$url}'"
                }
                set partName $refType
                set partType $refType
            } elseif {[string equal -nocase [lindex $refTypeInfo 1] schema]} {
                set partName *
                set partType *
            } else {
                set partName $refTypeInfo
                set partType $refTypeInfo
            }
        } else {
            ::log::log debug "\t\t has no ref has {[$element attributes]}"
            set childList [$element selectNodes -namespaces $nsList s:complexType/s:sequence/s:element]
            if {[llength $childList]} {
                ##
                ## Element defines another element layer
                ##
                set partName [$element getAttribute name]
                set partType $partName
                parseElementalType $mode results $serviceName $element $tns
            } else {
                set partName [$element getAttribute name]
                set partType [lindex [split [$element getAttribute type string:string] {:}] end]
            }
        }
        set partMax [$element getAttribute maxOccurs 1]
        ::log::log debug "\t\t part is {$partName} {$partType} {$partMax}"

        if {[string equal $partMax 1]} {
            lappend partList $partName [list type $partType comment {}]
        } else {
            lappend partList $partName [list type [string trimright ${partType} {()}]() comment {}]
        }
    }
    if {[llength $elements] == 0} {
        #
        # Validate this is not really a complex or simple type
        #
        set childList [$node hasChildNodes]
        foreach childNode $childList {
            if {[catch {$childNode setAttribute name $typeName}]} {
                continue
            }
            set childNodeType [$childNode localName]
            switch $childNodeType {
                complexType {
                    parseComplexType $mode serviceInfo $serviceName $childNode $tns
                    return
                }
                element {
                    parseElementalType $mode serviceInfo $serviceName $childNode $tns
                    return
                }
                simpleType {
                    parseSimpleType $mode serviceInfo $serviceName $childNode $tns
                    return
                }
            }
        }
        # have an element with a type only, so do the work here
        set partType [lindex [split [$node getAttribute type string:string] {:}] end]
        set partMax [$node getAttribute maxOccurs 1]
        if {[string equal $partMax 1]} {
            ##
            ## See if this is just a restriction on a simple type
            ##
            if {([lindex [TypeInfo $mode $serviceName $partType] 0] == 0) &&
                [string equal $typeName $partType]} {
                return
            } else {
                lappend partList $typeName [list type $partType comment {}]
            }
        } else {
            lappend partList $typeName [list type [string trimright ${partType} {()}]() comment {}]
        }
    }
    if {[llength $partList]} {
        dict set results types $typeName $partList
        ::WS::Utils::ServiceTypeDef $mode $serviceName $typeName $partList $tns
    } else {
        if {![dict exists $results types $typeName]} {
            set partList [list base string comment {} xns $tns]
            ::WS::Utils::ServiceSimpleTypeDef $mode $serviceName $typeName $partList
            dict set results simpletypes $typeName $partList
        }
    }
     ::log::log debug "\t returning"
}

###########################################################################
#
# Private Procedure Header - as this procedure is modified, please be sure
#                            that you update this header block. Thanks.
#
#>>BEGIN PRIVATE<<
#
# Procedure Name : ::WS::Utils::parseSimpleType
#
# Description : Parse a simnple type declaration from the Schema into our
#               internal representation
#
# Arguments :
#    dcitVar            - The name of the results dictionary
#    servcieName        - The service name this type belongs to
#    node               - The root node of the type definition
#    tns                - Namespace for this type
#
# Returns : Nothing
#
# Side-Effects : Defines mode type as specified by the Schema
#
# Exception Conditions : None
#
# Pre-requisite Conditions : None
#
# Original Author : Gerald W. Lester
#
#>>END PRIVATE<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  07/06/2006  G.Lester     Initial version
#
#
###########################################################################
proc ::WS::Utils::parseSimpleType {mode dictVar serviceName node tns} {
    upvar $dictVar results
    variable nsList

    ::log::log debug "Entering [info level 0]"

    set typeName [$node getAttribute name]
    ::log::log debug "Simple Type is $typeName"
    #puts "Simple Type is $typeName"
    set restrictionNode [$node selectNodes -namespaces $nsList s:restriction]
    if {[string equal $restrictionNode {}]} {
        set restrictionNode [$node selectNodes -namespaces $nsList s:list/s:simpleType/s:restriction]
    }
    if {[string equal $restrictionNode {}]} {
        set xml [string trim [$node asXML]]
        return \
            -code error \
            -errorcode [list WS $mode BADSMPTYPDEF [list $typeName $xml]] \
            "Bad simple type definition for '$typeName' :: \n'$xml'"
    }
    set baseType [lindex [split [$restrictionNode getAttribute base] {:}] end]
    set partList [list baseType $baseType xns $tns]
    set enumList {}
    foreach item [$restrictionNode childNodes] {
        set itemName [$item localName]
        set value [$item getAttribute value]
        #puts "\t Item {$itemName} = {$value}"
        if {[string equal $itemName {enumeration}]} {
            lappend enumList $value
        } else {
            lappend partList $itemName $value
        }
        if {[$item hasAttribute fixed]} {
            lappend partList fixed [$item getAttribute fixed]
        }
    }
    if {[llength $enumList]} {
        lappend partList enumeration $enumList
    }
    if {![dict exists $results types $typeName]} {
        ServiceSimpleTypeDef $mode $serviceName $typeName $partList
        dict set results simpletypes $typeName $partList
    }
}


###########################################################################
#
# Private Procedure Header - as this procedure is modified, please be sure
#                           that you update this header block. Thanks.
#
#>>BEGIN PRIVATE<<
#
# Procedure Name : ::WS::Utils::checkTags
#
# Description : Recursivly check the tags and values inside the tags
#
# Arguments :
#       mode        - Client/Server
#       serviceName - The service name
#       currNode    - The node to process
#       typeName    - The type name of the node
#
# Returns :     1 if ok, 0 otherwise
#
# Side-Effects :
#       ::errorCode - contains validation failure information if validation
#                       failed.
#
# Exception Conditions :        None
#
# Pre-requisite Conditions :    None
#
# Original Author : Arnulf Wiedemann
#
#>>END PRIVATE<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  08/13/2006  A.Wiedemann  Initial version
#       2  08/18/2006  G.Lester     Generalized to handle qualified XML
#
###########################################################################
proc ::WS::Utils::checkTags {mode serviceName currNode typeName} {

    ##
    ## Assume success
    ##
    set result 1

    ##
    ## Get the type information
    ##
    set typeInfoList [TypeInfo $mode $serviceName $typeName]
    set baseTypeName [string trimright $typeName {()}]
    set typeInfo [GetServiceTypeDef $mode $serviceName $baseTypeName]
    set isComplex [lindex $typeInfoList 0]
    set isArray [lindex $typeInfoList 1]

    if {$isComplex} {
        ##
        ## Is complex
        ##
        array set fieldInfoArr {}
        ##
        ## Build array of what is present
        ##
        foreach node [$currNode childNodes] {
            set localName [$node localName]
            lappend fieldInfoArr($localName) $node
        }
        ##
        ## Walk through each field and validate the information
        ##
        foreach {field fieldDef} [dict get $typeInfo definition] {
            array unset fieldInfoArr
            set fieldInfoArr(minOccurs) 0
            array set fieldInfoArr $fieldDef
            if {$fieldInfoArr(minOccurs) && ![info exists fieldInfoArr($field)]} {
                ##
                ## Fields was required but is missing
                ##
                set ::errorCode [list WS CHECK MISSREQFLD [list $type $field]]
                set result 0
            } elseif {$fieldInfoArr(minOccurs) &&
                      ($fieldInfoArr(minOccurs) > [llength $fieldInfoArr($field)])} {
                ##
                ## Fields was required and present, but not enough times
                ##
                set ::errorCode [list WS CHECK MINOCCUR [list $type $field]]
                set result 0
            } elseif {[info exists fieldInfoArr(maxOccurs)] &&
                      [string is integer fieldInfoArr(maxOccurs)] &&
                      ($fieldInfoArr(maxOccurs) < [llength $fieldInfoArr($field)])} {
                ##
                ## Fields was required and present, but too many times
                ##
                set ::errorCode [list WS CHECK MAXOCCUR [list $type $field]]
                set result 0
            } elseif {[info exists fieldInfoArr($field)]} {
                foreach node $fieldInfoArr($field) {
                    set result [checkTags $mode $serviceName $node $fieldInfoArr(type)]
                    if {!$result} {
                        break
                    }
                }
            }
            if {!$result} {
                break
            }
        }
    } else {
        ##
        ## Get the value
        ##
        set value [$currNode asText]
        set result [checkValue $mode $serviceName $baseTypeName $value]
    }

    return $result
}


###########################################################################
#
# Private Procedure Header - as this procedure is modified, please be sure
#                           that you update this header block. Thanks.
#
#>>BEGIN PRIVATE<<
#
# Procedure Name : ::WS::Utils::checkValue
#
# Description : Check a Value between tags of a XML document against the
#               type in the XML schema description
#
# Arguments :
#       mode        - Client/Server
#       serviceName - The name of the service
#       type        - The type to check
#       value       - The value to check
#
# Returns :     1 if ok or 0 if checking not ok
#
# Side-Effects :
#       ::errorCode - contains validation failure information if validation
#                       failed.
#
# Exception Conditions :        None
#
# Pre-requisite Conditions :    None
#
# Original Author : Arnulf Wiedemann
#
#>>END PRIVATE<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  08/14/2006  A.Wiedemann  Initial version
#       2  08/18/2006  G.Lester     Generalized to handle qualified XML
#
###########################################################################
proc ::WS::Utils::checkValue {mode serviceName type value} {

    set result 0
    array set typeInfos {
        minLength 0
        maxLength -1
        fixed false
    }
    array set typeInfos [GetServiceTypeDef $mode $serviceName $type]
    foreach {var value} [array get typeInfos] {
        set $var $value
    }
    set result 1

    if {$minLength >= 0 && [string length $value] < $minLength} {
        set ::errorCode [list WS CHECK VALUE_TO_SHORT [list $key $value $minLength $typeInfo]]
        set result 0
    } elseif {$maxLength >= 0 && [string length $value] > $maxLength} {
        set ::errorCode [list WS CHECK VALUE_TO_LONG [list $key $value $maxLength $typeInfo]]
        set result 0
    } elseif {[info exists enumeration] && ([lsearch -exact $enumeration $value] == -1)} {
        set errorCode [list WS CHECK VALUE_NOT_IN_ENUMERATION [list $key $value $enumerationVals $typeInfo]]
        set result 0
    } elseif {[info exists pattern] && (![regexp $pattern $value])} {
        set errorCode [list WS CHECK VALUE_NOT_MATCHES_PATTERN [list $key $value $pattern $typeInfo]]
        set result 0
    }

    return $result
}


###########################################################################
#
# Private Procedure Header - as this procedure is modified, please be sure
#                           that you update this header block. Thanks.
#
#>>BEGIN PRIVATE<<
#
# Procedure Name : ::WS::Utils::buildTags
#
# Description : Recursivly build the tags by checking the values to put
#               inside the tags and append to the dom tree resultTree
#
# Arguments :
#       mode        - Client/Server
#       serviceName - The service name
#       typeName    - The type for the tag
#       valueInfos  - The dictionary of the values
#       doc         - The DOM Document
#       currentNode - Node to append values to
#
# Returns :     nothing
#
# Side-Effects :        None
#
# Exception Conditions :        None
#
# Pre-requisite Conditions :    None
#
# Original Author : Arnulf Wiedemann
#
#>>END PRIVATE<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  08/13/2006  A.Wiedemann  Initial version
#       2  08/18/2006  G.Lester     Generalized to generate qualified XML
#
###########################################################################
proc ::WS::Utils::buildTags {mode serviceName typeName valueInfos doc currentNode} {
    upvar $valueInfos values

    ##
    ## Get the type information
    ##
    set baseTypeName [string trimright $typeName {()}]
    set typeInfo [GetServiceTypeDef $mode $serviceName $baseTypeName]
    set xns [dict get $typeInfo $mode $service $type xns]

    foreach {field fieldDef} [dict get $typeInfo definition] {
        ##
        ## Get info about this field and its type
        ##
        array unset fieldInfoArr
        set fieldInfoArr(minOccurs) 0
        array set fieldInfoArr $fieldDef
        set typeInfoList [TypeInfo $mode $serviceName $fieldInfoArr(type)]
        set fieldBaseType [string trimright $fieldInfoArr(type) {()}]
        set isComplex [lindex $typeInfoList 0]
        set isArray [lindex $typeInfoList 1]
        if {[dict exists $valueInfos $field]} {
            if {$isArray} {
                set valueList [dict get $valueInfos $field]
            } else {
                set valueList [list [dict get $valueInfos $field]]
            }
            set valueListLenght [llength $valueList]
        } else {
            set valueListLenght -1
        }

        if {$fieldInfoArr(minOccurs) && ![dict exists $valueInfos $field]} {
            ##
            ## Fields was required but is missing
            ##
            return \
                -errorcode [list WS CHECK MISSREQFLD [list $type $field]] \
                "Field '$field' of type '$typeName' was required but is missing"
        } elseif {$fieldInfoArr(minOccurs) &&
                  ($fieldInfoArr(minOccurs) > $valueListLenght)} {
            ##
            ## Fields was required and present, but not enough times
            ##
            set minOccurs $fieldInfoArr(minOccurs)
            return \
                -errorcode [list WS CHECK MINOCCUR [list $type $field $minOccurs $valueListLenght]] \
                "Field '$field' of type '$typeName' was required to occur $minOccurs time(s) but only occured $valueListLenght time(s)"
        } elseif {[info exists fieldInfoArr(maxOccurs)] &&
                  [string is integer fieldInfoArr(maxOccurs)] &&
                  ($fieldInfoArr(maxOccurs) < $valueListLenght)} {
            ##
            ## Fields was required and present, but too many times
            ##
            set minOccurs $fieldInfoArr(maxOccurs)
            return \
                -errorcode [list WS CHECK MAXOCCUR [list $type $field]] \
                "Field '$field' of type '$typeName' could only occur $minOccurs time(s) but occured $valueListLenght time(s)"
        } elseif {[dict exists $valueInfos $field]} {
            foreach value $valueList {
                $currentNode appendChild [$doc createElement $xns:$field retNode]
                if {$isComplex} {
                    buildTags $mode $serviceName $fieldBaseType $value $doc $retNode
                } else {
                    if {[info exists fieldInfoArr(enumeration)] &&
                        [info exists fieldInfoArr(fixed)] && $fieldInfoArr(fixed)} {
                        set value [lindex $fieldInfoArr(enumeration) 0]
                    }
                    if {[checkValue $mode $serviceName $fieldBaseType $value]} {
                        $retNode appendChild [$doc createTextNode $value]
                    } else {
                        set msg "Field '$field' of type '$typeName' "
                        switch -exact [lindex $::errorCode 2] {
                            VALUE_TO_SHORT {
                                append msg "value required to be $fieldInfoArr(minLength) long but is only [string length $value] long"
                            }
                            VALUE_TO_LONG {
                                append msg "value allowed to be only $fieldInfoArr(minLength) long but is [string length $value] long"
                            }
                            VALUE_NOT_IN_ENUMERATION {
                                append msg "value '$value' not in ([join $fieldInfoArr(enumeration) {, }])"
                            }
                            VALUE_NOT_MATCHES_PATTERN {
                                append msg "value '$value' does not match pattern: $fieldInfoArr(pattern)"
                            }
                        }
                        return \
                            -errorcode $::errorCode \
                            $msg
                    }
                }
            }
        }
    }
}



###########################################################################
#
# Private Procedure Header - as this procedure is modified, please be sure
#                           that you update this header block. Thanks.
#
#>>BEGIN PRIVATE<<
#
# Procedure Name : ::WS::Utils::setAttr
#
# Description : Set attributes on a DOM node
#
# Arguments :
#       node        - node to set attributes on
#       attrList    - List of attibute name value pairs
#
# Returns :     nothing
#
# Side-Effects :        None
#
# Exception Conditions :        None
#
# Pre-requisite Conditions :    None
#
# Original Author : Gerald Lester
#
#>>END PRIVATE<<
#
# Maintenance History - as this file is modified, please be sure that you
#                       update this segment of the file header block by
#                       adding a complete entry at the bottom of the list.
#
# Version     Date     Programmer   Comments / Changes / Reasons
# -------  ----------  ----------   -------------------------------------------
#       1  02/24/2011  G. Lester    Initial version
#
###########################################################################
if {[package vcompare [info patchlevel] 8.5] == -1} {
    ##
    ## 8.4, so can not use {*} expansion
    ##
    proc ::WS::Utils::setAttr {node attrList} {
        foreach {name value} $attrList {
            $node setAttribute $name $value
        }
    }
} else {
    ##
    ## 8.5 or later, so use {*} expansion
    ##
    proc ::WS::Utils::setAttr {node attrList} {
        $node setAttribute {*}$attrList
    }
}
