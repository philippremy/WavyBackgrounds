import { invoke } from "@tauri-apps/api/tauri";
import {emit, listen} from "@tauri-apps/api/event";
import {ask} from "@tauri-apps/api/dialog";
import {createSignal, onMount, Setter} from "solid-js";
import "./App.css";

import WallpaperOption from "./Components/Option.tsx";

interface WallpaperVideoEntry {
    friendly_name: String,
    video_url_plist: [number],
    video_url: String,
    preview_image_url: String,
    identifier: String,
    preview_image_save_path: null,
    video_save_path: string,
    localSaved: [() => boolean, Setter<boolean>],
    download_progress: [() => string, Setter<string>],
    downloadInProgress: [() => boolean, Setter<boolean>]
}

function App() {

    async function downloadVideo() {
        let selected_card = selected();
        let wallpaper_struct = entries.get(selected_card);
        let download_url = wallpaper_struct.video_url;
        let identifier = wallpaper_struct.identifier;
        wallpaper_struct.downloadInProgress[1](true);
        let unlisten = listen("progress_" + identifier, (event) => {
            wallpaper_struct.download_progress[1]((event.payload[1]/event.payload[0]*100).toString());
        })
        await invoke("download_file", {identifier: identifier, url: download_url}).then((result: string | null) => {
            if(result === null) {

            } else {
                wallpaper_struct.localSaved[1](true);
                wallpaper_struct.video_save_path = result!;
                console.log("Download successful. Path: " + result);
                wallpaper_struct.downloadInProgress[1](false);
            }
        })
    }

    let entries: Map<String, WallpaperVideoEntry> = new Map();
    let containerElement: HTMLDivElement | undefined;
    let [selected, setSelected] = createSignal("");

    onMount(() => {
        invoke("get_full_database_command").then((database) => {
            for (const databaseElement: WallpaperVideoEntry of database) {
                databaseElement.localSaved = createSignal(false);
                databaseElement.download_progress = createSignal("");
                databaseElement.downloadInProgress = createSignal(false);
                invoke("check_if_local_exists", {identifier: databaseElement.identifier}).then((event) => {
                    if(event.is_saved) {
                        databaseElement.localSaved[1](true);
                        databaseElement.video_save_path = event.save_path as string;
                    } else {
                        databaseElement.localSaved[1](false);
                        databaseElement.video_save_path = "";
                    }
                });
                let child = WallpaperOption(databaseElement.friendly_name, databaseElement.preview_image_url, databaseElement.video_url, databaseElement.identifier, selected, setSelected, databaseElement.localSaved[0], databaseElement.localSaved[1], databaseElement.download_progress[0], databaseElement.downloadInProgress[0]);
                containerElement?.appendChild(child as Node);
                entries.set(databaseElement.identifier, databaseElement);
            }
        })
    });

    return(
        <div>
            <div class={"container"} ref={containerElement}>
            </div>
            <div class={"footer"}>
                <div class={"footerSpaceSelection"}>
                    <button onClick={async () => {
                        await invoke("remove_all");
                    }}>Remove all dynamic backgrounds</button>
                    <button onClick={async ()=> {
                        await invoke("remove_current_space");
                    }}>Remove dynamic backgrounds on current space</button>
                </div>
                <div class={"footerButtons"}>
                    <button onClick={() => downloadVideo()}>Download</button>
                    <button class={"applyButton"} onclick={async () => {
                        await invoke("check_if_local_exists", {identifier: selected()}).then(async (answer)=> {
                            if(answer.is_saved) {
                                await invoke("apply_to_screen", {identifier: selected()});
                            } else {
                                await downloadVideo();
                                await invoke("apply_to_screen", {identifier: selected()});
                            }
                        });
                    }}>Apply</button>
                </div>
            </div>
        </div>
    );
}
export default App;
