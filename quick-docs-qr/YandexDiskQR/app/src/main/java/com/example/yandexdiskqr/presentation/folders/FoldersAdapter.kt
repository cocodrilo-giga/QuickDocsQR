package com.example.yandexdiskqr.presentation.folders

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.example.yandexdiskqr.data.model.YandexDiskFolder
import com.example.yandexdiskqr.databinding.ItemFolderBinding

class FoldersAdapter(
    private val onFolderClick: (YandexDiskFolder) -> Unit
) : ListAdapter<YandexDiskFolder, FoldersAdapter.FolderViewHolder>(FolderDiffCallback()) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): FolderViewHolder {
        val binding = ItemFolderBinding.inflate(
            LayoutInflater.from(parent.context),
            parent,
            false
        )
        return FolderViewHolder(binding)
    }

    override fun onBindViewHolder(holder: FolderViewHolder, position: Int) {
        holder.bind(getItem(position))
    }

    inner class FolderViewHolder(
        private val binding: ItemFolderBinding
    ) : RecyclerView.ViewHolder(binding.root) {

        fun bind(folder: YandexDiskFolder) {
            binding.folderName.text = folder.name
            binding.root.setOnClickListener { onFolderClick(folder) }
        }
    }

    private class FolderDiffCallback : DiffUtil.ItemCallback<YandexDiskFolder>() {
        override fun areItemsTheSame(oldItem: YandexDiskFolder, newItem: YandexDiskFolder): Boolean {
            return oldItem.path == newItem.path
        }

        override fun areContentsTheSame(oldItem: YandexDiskFolder, newItem: YandexDiskFolder): Boolean {
            return oldItem == newItem
        }
    }
}
