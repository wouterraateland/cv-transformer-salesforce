import { LightningElement, api, track, wire } from "lwc";
import candidateAttachCV from "@salesforce/apex/CVTransformerApi.candidateAttachCV";
import candidateAttachmentsList from "@salesforce/apex/CVTransformerApi.candidateAttachmentsList";
import candidateContextGet from "@salesforce/apex/CVTransformerApi.candidateContextGet";
import candidateExportCV from "@salesforce/apex/CVTransformerApi.candidateExportCV";
import candidateLink from "@salesforce/apex/CVTransformerApi.candidateLink";
import candidateUnlink from "@salesforce/apex/CVTransformerApi.candidateUnlink";
import configUpsert from "@salesforce/apex/CVTransformerApi.configUpsert";
import contactDataGet from "@salesforce/apex/CVTransformerApi.contactDataGet";
import contactTransformCv from "@salesforce/apex/CVTransformerApi.contactTransformCv";
import contentVersionDataGet from "@salesforce/apex/CVTransformerApi.contentVersionDataGet";

export default class CVTransformer extends LightningElement {
  @api recordId;
  @track data = {};
  error;
  state = "loading";

  organization_id;
  candidate_id;
  candidate_secret_editable;

  external_attachments = [];
  external_candidate_data = null;
  iframe_ready = false;

  @wire(contactDataGet, { contact_id: "$recordId" })
  wiredData({ error, data }) {
    if (data) {
      this.data = data;
      this.error = null;
      this.state = this.data.organization_id ? "edit" : "setup";
    } else if (error) {
      this.data = {};
      this.error = error;
      this.state = "error";
    }
  }

  postIframeWhenReady() {
    if (!this.iframe_ready) return;
    const iframe = this.template.querySelector("iframe");
    if (!iframe || !iframe.contentWindow) return;

    iframe.contentWindow.postMessage(
      {
        avatar: this.external_candidate_data?.avatar || null,
        id: this.recordId,
        name:
          (this.external_candidate_data?.firstName ?? "") +
          " " +
          (this.external_candidate_data?.lastName ?? ""),
        type: "external-candidate-data",
        url: window.location.href,
        values: this.external_candidate_data
      },
      this.iframeUrl
    );
    iframe.contentWindow.postMessage(
      {
        attachments: this.external_attachments ?? [],
        type: "external-attachments"
      },
      this.iframeUrl
    );
  }

  @wire(candidateContextGet, { contact_id: "$recordId" })
  wiredContext({ data }) {
    if (!data) return;
    try {
      this.external_candidate_data = JSON.parse(data);
      this.postIframeWhenReady();
    } catch (error) {
      console.log(error);
    }
  }

  @wire(candidateAttachmentsList, { contact_id: "$recordId" })
  wiredAttachments({ data }) {
    if (!data) return;
    try {
      this.external_attachments = JSON.parse(data);
      this.postIframeWhenReady();
    } catch (error) {
      console.log(error);
    }
  }

  get isLoading() {
    return this.state === "loading";
  }

  get isEdit() {
    return this.state === "edit";
  }

  get isSetup() {
    return this.state === "setup";
  }

  get isError() {
    return this.state === "error";
  }

  get iframeUrl() {
    return `https://www.cv-transformer.com/candidates/${
      this.data.candidate_id
    }?s=${this.data.candidate_secret}&context=${this.data.ats}`;
  }

  onSetup() {
    this.error = null;
    this.state = "setup";
  }

  onSetupCancel() {
    this.error = null;
    this.state = "edit";
  }

  setError(error) {
    console.log(error);
    if (error.body && error.body.message) this.error = error.body.message;
    else if (error.message) this.error = error.message;
    else if (typeof error === "string") this.error = error;
    else if (error instanceof Error) this.error = error.toString();
    else this.error = "An unknown error occurred.";
  }

  async onSetupSubmit(event) {
    event.preventDefault();
    this.state = "loading";
    try {
      const inputs = [...this.template.querySelectorAll("lightning-input")];
      const values = Object.fromEntries(
        inputs.map((input) => [input.name, input.value])
      );
      const organization_id = await configUpsert({ api_key: values.api_key });
      this.data = { ...this.data, organization_id };
      this.error = null;
      this.state = "edit";
    } catch (error) {
      this.data = {};
      this.setError(error);
      this.state = "setup";
    }
  }

  async onCandidateCreate() {
    this.state = "loading";
    try {
      this.data = await contactTransformCv({ contact_id: this.recordId });
      this.error = null;
    } catch (error) {
      this.setError(error);
    }
    this.state = "edit";
  }

  async onCandidateSelect() {
    // eslint-disable-next-line no-alert
    const candidate_id_or_url = prompt(
      "Enter CV-Transformer candidate ID or URL"
    );
    let candidate_id = "";
    try {
      const url = new URL(candidate_id_or_url);
      candidate_id = url.pathname.split("/").pop();
    } catch {
      candidate_id = candidate_id_or_url;
    }
    if (!candidate_id) return;
    this.state = "loading";
    try {
      this.data = await candidateLink({
        candidate_id,
        contact_id: this.recordId
      });
      this.error = null;
    } catch (error) {
      this.setError(error);
    }
    this.state = "edit";
  }

  async onCandidateUnlink() {
    this.state = "loading";
    try {
      await candidateUnlink({ contact_id: this.recordId });
      this.data = { ...this.data, candidate_id: null, candidate_secret: null };
      this.error = null;
    } catch (error) {
      this.setError(error);
    }
    this.state = "edit";
  }

  async onAttachmentSelect(event) {
    this.state = "loading";
    try {
      if (event.detail === "regular" || event.detail === "anonymous") {
        await candidateExportCV({
          contact_id: this.recordId,
          export_type: event.detail
        });
        window.location.reload();
      } else
        await candidateAttachCV({
          contact_id: this.recordId,
          content_version_id: event.detail
        });
    } catch (error) {
      this.setError(error);
    }
    this.state = "edit";
  }

  async onMessage(event) {
    if (
      typeof event.data !== "object" ||
      event.data === null ||
      Array.isArray(event.data)
    )
      return;

    if (
      event.data.type === "candidate-export" &&
      typeof event.data.export_type === "string"
    ) {
      this.state = "loading";
      try {
        await candidateExportCV({
          contact_id: this.recordId,
          export_type: event.data.export_type
        });
        window.location.reload();
      } catch (error) {
        this.setError(error);
      }
      this.state = "edit";
    }

    if (event.data.type === "iframe-ready") {
      this.iframe_ready = true;
      this.postIframeWhenReady();
    }

    if (event.data.type === "content-version-base64-request") {
      const iframe = this.template.querySelector("iframe");
      if (!iframe || !iframe.contentWindow) return;

      const { base64, extension, title } = await contentVersionDataGet({
        content_version_id: event.data.content_version_id
      });
      let filename = title;
      if (!filename.toLowerCase().endsWith(`.${extension.toLowerCase()}`))
        filename += `.${extension.toLowerCase()}`;

      iframe.contentWindow.postMessage(
        { base64, filename, type: "content-version-base64-response" },
        this.iframeUrl
      );
    }
  }

  connectedCallback() {
    if (!this.boundOnMessage) this.boundOnMessage = this.onMessage.bind(this);
    window.addEventListener("message", this.boundOnMessage);
  }

  disconnectedCallback() {
    if (this.boundOnMessage)
      window.removeEventListener("message", this.boundOnMessage);
  }
}
