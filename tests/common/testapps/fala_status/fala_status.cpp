/***************************************************************************
**
** Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
** All rights reserved.
** Contact: Nokia Corporation (directui@nokia.com)
**
** This file is part of applauncherd
**
** If you have questions regarding the use of this file, please contact
** Nokia at directui@nokia.com.
**
** This library is free software; you can redistribute it and/or
** modify it under the terms of the GNU Lesser General Public
** License version 2.1 as published by the Free Software Foundation
** and appearing in the file LICENSE.LGPL included in the packaging
** of this file.
**
****************************************************************************/

#include <iostream>
#include <unistd.h>

int main(int argc, char ** argv)
{
    int usr_id = getuid();
    int grp_id = getgid();

    std::cerr << "uid=" << usr_id <<"\n";
    std::cerr << "gid=" << grp_id <<"\n";

    usleep(5000);
    _exit(29);
}
