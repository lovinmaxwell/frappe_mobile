import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../utils/cache_helper.dart';
import '../utils/frappe_alert.dart';
import '../utils/helpers.dart';
import '../utils/config_helper.dart';
import '../utils/enums.dart';

import '../config/palette.dart';

import 'doctype_view.dart';
import 'activate_modules.dart';

import '../datamodels/desk_sidebar_items_response.dart';
import '../app/locator.dart';
import '../services/api/api.dart';

import '../widgets/frappe_button.dart';
import '../widgets/card_list_tile.dart';

class ModuleView extends StatefulWidget {
  @override
  _ModuleViewState createState() => _ModuleViewState();
}

class _ModuleViewState extends State<ModuleView> {
  Future _getData() async {
    var connectionStatus = Provider.of<ConnectivityStatus>(
      context,
    );
    var cachedModules = {};
    DeskSidebarItemsResponse modules;

    var isOnline = await verifyOnline();

    if ((connectionStatus == null ||
            connectionStatus == ConnectivityStatus.offline) &&
        !isOnline) {
      var response = await CacheHelper.getCache('deskSidebarItems');
      response = response["data"];
      if (response != null) {
        modules = DeskSidebarItemsResponse.fromJson(response);
      } else {
        throw Response(statusCode: HttpStatus.serviceUnavailable);
      }
    } else {
      modules = await locator<Api>().getDeskSideBarItems();
    }
    var activeModules;
    if (ConfigHelper().activeModules != null) {
      activeModules = ConfigHelper().activeModules;
    } else {
      activeModules = {};
    }
    for (var module in activeModules.keys) {
      cachedModules[module] = await CacheHelper.getCache("${module}Doctypes");
    }

    return {
      "cachedModules": cachedModules,
      "modules": modules,
    };
  }

  @override
  Widget build(BuildContext context) {
    var connectionStatus = Provider.of<ConnectivityStatus>(
      context,
    );
    return Scaffold(
      backgroundColor: Palette.bgColor,
      appBar: AppBar(
        title: Text('Modules'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: FutureBuilder(
          future: _getData(),
          builder: (context, snapshot) {
            if (snapshot.hasData &&
                snapshot.connectionState == ConnectionState.done) {
              var activeModules;
              if (ConfigHelper().activeModules != null) {
                activeModules = ConfigHelper().activeModules;
              } else {
                activeModules = {};
              }
              if (activeModules.keys.isEmpty) {
                return Center(
                  child: Container(
                    color: Colors.white,
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Activate Modules'),
                        FrappeFlatButton(
                          onPressed: () async {
                            var nav = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return ActivateModules();
                                },
                              ),
                            );

                            if (nav) {
                              setState(() {});
                            }
                          },
                          title: 'Activate Modules',
                          buttonType: ButtonType.primary,
                        )
                      ],
                    ),
                  ),
                );
              }
              DeskSidebarItemsResponse deskSidebarItems =
                  snapshot.data["modules"];
              List<DeskItem> modules = [
                ...deskSidebarItems.message.modules,
                ...deskSidebarItems.message.administration,
                ...deskSidebarItems.message.domains
              ];
              var modulesWidget = modules.where((m) {
                return activeModules.keys.contains(m.name) &&
                    activeModules[m.name].length > 0;
              }).map<Widget>((module) {
                var syncDate;
                var c = snapshot.data["cachedModules"][module.name];
                if (c["data"] == null) {
                  syncDate = "Not Synced";
                } else {
                  syncDate = timeago.format(
                    c["timestamp"],
                  );
                }
                return Slidable(
                  actionPane: SlidableDrawerActionPane(),
                  secondaryActions: <Widget>[
                    IconSlideAction(
                      caption: 'Download',
                      color: Palette.primaryButtonColor,
                      icon: Icons.cloud_download,
                      onTap: () async {
                        var isOnline = await verifyOnline();
                        // var shouldCache = await CacheHelper.shouldCacheApi();
                        // if (!shouldCache) {
                        //   FrappeAlert.warnAlert(
                        //     title:
                        //         'Please wait until Background Syncing is finished',
                        //     context: context,
                        //   );
                        //   return;
                        // }
                        if ((connectionStatus == null ||
                                connectionStatus ==
                                    ConnectivityStatus.offline) &&
                            !isOnline) {
                          FrappeAlert.errorAlert(
                              title: "Unable to Download, App is Offline",
                              context: context);
                        } else {
                          FrappeAlert.infoAlert(
                            title: 'Downloading ${module.name}...',
                            context: context,
                          );
                          try {
                            await putSharedPrefValue(
                              "cacheApi",
                              false,
                            );
                            await CacheHelper.cacheModule(module.name);
                            await putSharedPrefValue(
                              "cacheApi",
                              true,
                            );
                            FrappeAlert.infoAlert(
                              title: '${module.name} is Downloaded',
                              context: context,
                            );
                          } catch (e) {
                            await putSharedPrefValue(
                              "cacheApi",
                              true,
                            );
                            FrappeAlert.errorAlert(
                              title: '${module.name} Downloading Failed',
                              context: context,
                            );
                          }
                          setState(() {});
                        }
                      },
                    ),
                    IconSlideAction(
                      caption: syncDate,
                      color: Colors.white,
                      icon: Icons.sync,
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 10.0, right: 10.0, top: 8.0),
                    child: CardListTile(
                      title: Text(module.label),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return DoctypeView(module.name);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                );
              }).toList();
              return ListView(
                children: modulesWidget,
              );
            } else if (snapshot.hasError) {
              return handleError(snapshot.error);
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
    );
  }
}
