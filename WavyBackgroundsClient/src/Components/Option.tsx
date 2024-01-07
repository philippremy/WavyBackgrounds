import "./Option.css";
import {createEffect, onMount, Setter} from "solid-js";
import {ask, message} from "@tauri-apps/api/dialog";
import {invoke} from "@tauri-apps/api/tauri";

export default function WallpaperOption(name: String, imageURL: String, videoURL: String, identifier: string, selected: () => string, setSelected: Setter<string>, localSaved: () => boolean, setLocalSaved: Setter<boolean>, downloadProgress: () => string, downloadInProgress: () => boolean) {

    let selectedContainer: HTMLDivElement | undefined;
    let progressBar: HTMLDivElement | undefined;
    let deleteDiv: HTMLDivElement | undefined;

    onMount(() => {
        const root = document.documentElement;
        root.style.setProperty("--degree_" + identifier, 0 + "deg");
    });

    createEffect(() => {
        if(downloadInProgress()) {
            progressBar?.classList.add("visible");
        } else {
            progressBar?.classList.remove("visible");
        }
    });

    createEffect(() => {
        let root = document.documentElement;
        let progress = downloadProgress();
        if(progress === "") {
            root.style.setProperty("--degree_" + identifier, 0 + "deg");
        } else if(progress === "NaN") {
            root.style.setProperty("--degree_" + identifier, 0 + "deg");
        } else {
            let degree = parseFloat(progress) * 3.6;
            root.style.setProperty("--degree_" + identifier, degree + "deg");
        }
    })

    createEffect(() => {
        if(selected() === identifier) {
            selectedContainer?.classList.add("selected");
        } else {
            selectedContainer?.classList.remove("selected");
        }
    });

    return(
        <div class={"optionContainer"} ref={selectedContainer} onclick={(event) => {
            event.preventDefault();
            if(event.altKey) {
                if(!localSaved()) {} else {
                    ask("Are you sure you want to delete the local video download?", {type: "info", title: "Confirm"}).then((selection) => {
                        if(selection) {
                            invoke("delete_local", {identifier: identifier}).then((result) => {
                                if(result) {
                                    setLocalSaved(false);
                                } else {
                                    message("Failed to delete local video file.", {title: "LocalDeleteOperationError", type: "error"}).then(() => {});
                                }
                            })
                        } else {}
                    })
                }
            } else {
                setSelected(identifier);
            }
        }} onMouseOver={() => {
            if(localSaved()) {
                deleteDiv?.classList.add("visible");
            }
        }} onMouseLeave={() => {
            deleteDiv?.classList.remove("visible");
        }}>
            <img src={imageURL} class={"imagePreview"} alt={"NADA"}/>
            <p class={"textName"}>{name}</p>
            <p class={"identifier"}>{identifier}</p>
            <div hidden={!localSaved()} class={"localSave"}></div>
            <div class={"progressDiv"} ref={progressBar} style={"background-image: conic-gradient(rgb(0, 122, 255) var(--degree_" + identifier + "), white 1deg);"}></div>
            <div class="deleteDiv" ref={deleteDiv} onClick={() => {
                if(!localSaved()) {} else {
                    ask("Are you sure you want to delete the local video download?", {type: "info", title: "Confirm"}).then((selection) => {
                        if(selection) {
                            invoke("delete_local", {identifier: identifier}).then((result) => {
                                if(result) {
                                    setLocalSaved(false);
                                } else {
                                    message("Failed to delete local video file.", {title: "LocalDeleteOperationError", type: "error"}).then(() => {});
                                }
                            })
                        } else {}
                    })
                }
            }}>
                <div class="dot"></div>
                <div class="dot"></div>
                <div class="dot"></div>
            </div>
        </div>
    );
}